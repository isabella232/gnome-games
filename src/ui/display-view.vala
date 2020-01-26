// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DisplayView : Object, UiView {
	private const uint FOCUS_OUT_DELAY_MILLISECONDS = 500;

	public signal void back ();

	private DisplayBox box;
	private DisplayHeaderBar header_bar;

	public Gtk.Widget content_box {
		get { return box; }
	}

	public Gtk.Widget title_bar {
		get { return header_bar; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active) {
				is_fullscreen = false;

				if (box.runner != null) {
					box.runner.stop ();
					box.runner = null;
				}
			}
		}
	}

	public Gtk.Window window { get; construct; }

	public bool is_fullscreen { get; set; }
	public bool is_showing_snapshots { get; set; }

	private Settings settings;

	private Cancellable run_game_cancellable;
	private Cancellable quit_game_cancellable;

	private ResumeDialog resume_dialog;
	private ResumeFailedDialog resume_failed_dialog;
	private QuitDialog quit_dialog;

	private long focus_out_timeout_id;

	private const ActionEntry[] action_entries = {
		{ "load-snapshot", load_snapshot },
	};

	public DisplayView (Gtk.Window window) {
		Object (window: window);
	}

	construct {
		box = new DisplayBox ();
		header_bar = new DisplayHeaderBar ();

		box.back.connect (on_display_back);
		header_bar.back.connect (on_display_back);

		box.snapshots_hidden.connect (on_snapshots_hidden);

		settings = new Settings ("org.gnome.Games");

		bind_property ("is-fullscreen", box,
		               "is-fullscreen", BindingFlags.BIDIRECTIONAL);
		bind_property ("is-fullscreen", header_bar,
		               "is-fullscreen", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-showing-snapshots", box,
		               "is-showing-snapshots", BindingFlags.BIDIRECTIONAL);
		bind_property ("is-showing-snapshots", header_bar,
		               "is-showing-snapshots", BindingFlags.BIDIRECTIONAL);

		focus_out_timeout_id = -1;

		var action_group = new SimpleActionGroup ();
		action_group.add_action_entries (action_entries, this);
		window.insert_action_group ("display", action_group);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		// Mouse button 8 is the navigation previous button
		if (event.button == 8) {
			back ();
			return true;
		}

		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (window.get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);
		var ctrl_pressed = (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK;

		if (box.on_key_press_event (keyval, event.state & default_modifiers))
			return true;

		if ((keyval == Gdk.Key.f || keyval == Gdk.Key.F) && ctrl_pressed &&
		    header_bar.can_fullscreen && !is_showing_snapshots) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (keyval == Gdk.Key.F11 && header_bar.can_fullscreen &&
		    !is_showing_snapshots) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (keyval == Gdk.Key.Escape) {
			on_escape_key_pressed ();

			return true;
		}

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((window.get_direction () == Gtk.TextDirection.LTR) && keyval == Gdk.Key.Left) ||
		     ((window.get_direction () == Gtk.TextDirection.RTL) && keyval == Gdk.Key.Right))) {
			on_display_back ();

			return true;
		}

		// Shortcuts for the Savestates manager
		if (!box.runner.supports_savestates)
			return false;

		if (is_showing_snapshots)
			return false;

		if (((keyval == Gdk.Key.a || keyval == Gdk.Key.A) && ctrl_pressed) ||
		     (keyval == Gdk.Key.F4)) {
			is_showing_snapshots = true;

			return true;
		}

		if (((keyval == Gdk.Key.s || keyval == Gdk.Key.S) && ctrl_pressed) ||
		     (keyval == Gdk.Key.F2)){
			create_new_savestate ();

			return true;
		}

		if ((keyval == Gdk.Key.d || keyval == Gdk.Key.D) && ctrl_pressed ||
		    (keyval == Gdk.Key.F3)) {
			load_latest_savestate ();

			return true;
		}

		return false;
	}

	private void on_escape_key_pressed () {
		if (is_showing_snapshots)
			on_display_back (); // Hide Savestates menu
		else if (header_bar.can_fullscreen) {
			is_fullscreen = false;
			settings.set_boolean ("fullscreen", false);
		}
	}

	private void create_new_savestate () {
		box.runner.pause ();
		box.runner.try_create_savestate (false);
		box.runner.resume ();
		box.runner.get_display ().grab_focus ();
	}

	private void load_latest_savestate () {
		var savestates = box.runner.get_savestates ();

		if (savestates.length == 0)
			return;

		box.runner.pause ();
		box.runner.preview_savestate (savestates[0]);

		try {
			box.runner.load_previewed_savestate ();
		}
		catch (Error e) {
			warning ("Failed to load snapshot: %s", e.message);
		}

		box.runner.resume ();
		box.runner.get_display ().grab_focus ();
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (resume_dialog != null)
			return resume_dialog.is_active && resume_dialog.gamepad_button_press_event (event);

		if (resume_failed_dialog != null)
			return resume_failed_dialog.is_active && resume_failed_dialog.gamepad_button_press_event (event);

		if (quit_dialog != null)
			return quit_dialog.is_active && quit_dialog.gamepad_button_press_event (event);

		if (!window.is_active || !window.get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		if (box.gamepad_button_press_event (event))
			return true;

		switch (button) {
		case EventCode.BTN_MODE:
			on_display_back ();

			return true;
		default:
			return false;
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return false;
	}

	private void on_display_back () {
		if (is_showing_snapshots) {
			box.runner.preview_current_state ();
			is_showing_snapshots = false;

			return;
		}

		back ();
	}

	public void run_game (Game game) {
		// If there is a game already running we have to quit it first
		if (box.runner != null && !quit_game ())
			return;

		if (run_game_cancellable != null)
			run_game_cancellable.cancel ();

		var cancellable = new Cancellable ();
		run_game_cancellable = cancellable;

		run_game_with_cancellable (game, cancellable);

		// Only reset the cancellable if another one didn't replace it.
		if (run_game_cancellable == cancellable)
			run_game_cancellable = null;
	}

	private void run_game_with_cancellable (Game game, Cancellable cancellable) {
		header_bar.game_title = game.name;
		box.header_bar.game_title = game.name;

		// Reset the UI parts depending on the runner to avoid an
		// inconsistent state is case we couldn't retrieve it.
		reset_display_page ();

		var runner = try_get_runner (game);
		if (runner == null)
			return;

		header_bar.can_fullscreen = runner.can_fullscreen;
		box.header_bar.can_fullscreen = runner.can_fullscreen;
		header_bar.runner = runner;
		box.runner = runner;
		header_bar.media_set = runner.media_set;
		box.header_bar.media_set = runner.media_set;

		is_fullscreen = settings.get_boolean ("fullscreen") && runner.can_fullscreen;

		if (!runner.can_resume) {
			try_run_with_cancellable (runner, false, cancellable);
			return;
		}

		var response = Gtk.ResponseType.NONE;
		if (runner.can_resume)
			response = prompt_resume_with_cancellable (cancellable);

		if (response != Gtk.ResponseType.NONE) {
			var resume = (response == Gtk.ResponseType.ACCEPT);

			if (!try_run_with_cancellable (runner, resume, cancellable))
				prompt_resume_fail_with_cancellable (runner, cancellable);
		}
	}

	private Runner? try_get_runner (Game game) {
		var collection = Application.get_default ().get_collection ();
		var runner = collection.create_runner (game);
		if (runner == null) {
			reset_display_page ();
			box.display_running_game_failed (game, _("No runner found"));

			return null;
		}

		string error_message;
		if (runner.try_init_phase_one (out error_message))
			return runner;

		reset_display_page ();
		box.display_running_game_failed (game, error_message);

		return null;
	}

	private Gtk.ResponseType prompt_resume_with_cancellable (Cancellable cancellable) {
		if (resume_dialog != null)
			return Gtk.ResponseType.NONE;

		resume_dialog = new ResumeDialog ();
		resume_dialog.transient_for = window;

		cancellable.cancelled.connect (() => {
			resume_dialog.destroy ();
			resume_dialog = null;
		});

		var response = resume_dialog.run ();

		// The null check is necessary because the dialog could already
		// be canceled by this point
		if (resume_dialog != null) {
			resume_dialog.destroy ();
			resume_dialog = null;
		}

		return (Gtk.ResponseType) response;
	}

	private bool try_run_with_cancellable (Runner runner, bool resume, Cancellable cancellable) {
		try {
			if (resume)
				box.runner.load_previewed_savestate ();
			else
				runner.start ();

			return true;
		}
		catch (Error e) {
			warning (e.message);

			return false;
		}
	}

	private void prompt_resume_fail_with_cancellable (Runner runner, Cancellable cancellable) {
		if (resume_failed_dialog != null)
			return;

		resume_failed_dialog = new ResumeFailedDialog ();
		resume_failed_dialog.transient_for = window;

		cancellable.cancelled.connect (() => {
			resume_failed_dialog.destroy ();
			resume_failed_dialog = null;
		});

		var response = resume_failed_dialog.run ();
		resume_failed_dialog.destroy ();
		resume_failed_dialog = null;

		if (cancellable.is_cancelled ())
			response = Gtk.ResponseType.CANCEL;

		if (response == Gtk.ResponseType.CANCEL) {
			box.runner = null;
			back ();

			return;
		}

		try {
			runner.start ();
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	public bool quit_game () {
		if (run_game_cancellable != null)
			run_game_cancellable.cancel ();

		if (quit_game_cancellable != null)
			quit_game_cancellable.cancel ();

		var cancellable = new Cancellable ();
		quit_game_cancellable = cancellable;

		var result = quit_game_with_cancellable (cancellable);

		// Only reset the cancellable if another one didn't replace it.
		if (quit_game_cancellable == cancellable)
			quit_game_cancellable = null;

		return result;
	}

	public bool quit_game_with_cancellable (Cancellable cancellable) {
		if (box.runner == null)
			return true;

		box.runner.pause ();

		if (!box.runner.can_support_savestates) {
			// Game does not and will not support savestates (e.g. Steam games)
			// => Progress cannot be saved so game can be quit safely
			box.runner.stop ();
			return true;
		}

		if (box.runner.try_create_savestate (true) != null) {
			// Progress saved => can quit game safely
			box.runner.stop ();
			return true;
		}

		// Failed to save progress => warn the user of unsaved progress
		// via the QuitDialog
		if (quit_dialog != null)
			return false;

		quit_dialog = new QuitDialog ();
		quit_dialog.transient_for = window;

		cancellable.cancelled.connect (() => {
			quit_dialog.destroy ();
			quit_dialog = null;
		});

		var response = quit_dialog.run ();

		// The null check is necessary because the dialog could already
		// be canceled by this point
		if (quit_dialog != null) {
			quit_dialog.destroy ();
			quit_dialog = null;
		}

		if (cancellable.is_cancelled ())
			return cancel_quitting_game ();

		if (response == Gtk.ResponseType.ACCEPT)
			return true;

		return cancel_quitting_game ();
	}

	private bool cancel_quitting_game () {
		if (box.runner != null)
			box.runner.resume ();

		return false;
	}

	private void reset_display_page () {
		header_bar.hide_secondary_menu_button ();

		header_bar.can_fullscreen = false;
		box.header_bar.can_fullscreen = false;
		header_bar.runner = null;
		box.runner = null;
		header_bar.media_set = null;
		box.header_bar.media_set = null;
	}

	public void on_snapshots_hidden () {
		if (window.is_active) {
			box.runner.resume ();
			box.runner.get_display ().grab_focus ();
		}
	}

	public void update_pause (bool with_delay) {
		if (focus_out_timeout_id != -1) {
			Source.remove ((uint) focus_out_timeout_id);
			focus_out_timeout_id = -1;
		}

		if (!can_update_pause ())
			return;

		if (window.is_active) {
			if (!is_showing_snapshots)
				box.runner.resume ();
		}
		else if (with_delay)
			focus_out_timeout_id = Timeout.add (FOCUS_OUT_DELAY_MILLISECONDS, on_focus_out_delay_elapsed);
		else
			box.runner.pause ();
	}

	private bool on_focus_out_delay_elapsed () {
		focus_out_timeout_id = -1;

		if (!can_update_pause ())
			return false;

		if (!window.is_active)
			box.runner.pause ();

		return false;
	}

	private bool can_update_pause () {
		if (box.runner == null)
			return false;

		if (run_game_cancellable != null)
			return false;

		if (quit_game_cancellable != null)
			return false;

		return true;
	}

	private void load_snapshot () {
		try {
			box.runner.load_previewed_savestate ();
		}
		catch (Error e) {
			critical ("Failed to load snapshot: %s", e.message);
		}

		is_showing_snapshots = false;
	}
}
