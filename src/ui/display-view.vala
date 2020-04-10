// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-view.ui")]
private class Games.DisplayView : Gtk.Box, UiView {
	private const uint FOCUS_OUT_DELAY_MILLISECONDS = 500;

	public signal void back ();

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private ErrorDisplay error_display;
	[GtkChild]
	private Gtk.Overlay display_overlay;
	[GtkChild]
	private DisplayBin display_bin;
	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private DisplayHeaderBar header_bar;
	[GtkChild]
	private FlashBox flash_box;
	[GtkChild]
	private SnapshotsList snapshots_list;

	public Gtk.Widget content_box {
		get { return this; }
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

				if (runner != null) {
					runner.stop ();
					runner = null;
				}

				update_actions ();
			}
		}
	}

	public Gtk.Window window { get; construct; }

	public bool can_fullscreen { get; set; }
	public bool is_fullscreen { get; set; }
	public bool is_showing_snapshots { get; set; }
	public string game_title { get; set; }

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			if (runner != null)
				runner.snapshot_created.disconnect (flash_box.flash);

			stack.visible_child = display_overlay;

			_runner = value;
			remove_display ();
			header_bar.runner = runner;

			if (runner == null)
				return;

			var display = runner.get_display ();
			set_display (display);

			snapshots_list.runner = value;

			runner.snapshot_created.connect (flash_box.flash);
		}
	}

	private Settings settings;

	private Cancellable run_game_cancellable;
	private Cancellable quit_game_cancellable;

	private ResumeDialog resume_dialog;
	private ResumeFailedDialog resume_failed_dialog;
	private QuitDialog quit_dialog;
	private RestartDialog restart_dialog;

	private long focus_out_timeout_id;
	private Game game;

	private SimpleActionGroup action_group;
	private const ActionEntry[] action_entries = {
		{ "load-snapshot",  load_snapshot  },
		{ "show-snapshots", show_snapshots },
		{ "restart",        restart        },
	};

	public DisplayView (Gtk.Window window) {
		Object (window: window);
	}

	construct {
		settings = new Settings ("org.gnome.Games");

		focus_out_timeout_id = -1;

		action_group = new SimpleActionGroup ();
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
		if (!get_mapped ())
			return false;

		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (window.get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);
		var ctrl_pressed = (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK;

		if (runner == null)
			return false;

		if (is_showing_snapshots)
			return snapshots_list.on_key_press_event (keyval, event.state & default_modifiers);

		if (runner.key_press_event (keyval, event.state & default_modifiers))
			return true;

		if ((keyval == Gdk.Key.f || keyval == Gdk.Key.F) && ctrl_pressed &&
		    can_fullscreen && !is_showing_snapshots) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (keyval == Gdk.Key.F11 && can_fullscreen && !is_showing_snapshots) {
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

		if (runner == null)
			return false;

		if (!runner.supports_snapshots)
			return false;

		if (is_showing_snapshots)
			return false;

		if (((keyval == Gdk.Key.a || keyval == Gdk.Key.A) && ctrl_pressed) ||
		     (keyval == Gdk.Key.F4)) {
			show_snapshots ();

			return true;
		}

		if (((keyval == Gdk.Key.s || keyval == Gdk.Key.S) && ctrl_pressed) ||
		     (keyval == Gdk.Key.F2)) {
			create_new_snapshot ();

			return true;
		}

		if ((keyval == Gdk.Key.d || keyval == Gdk.Key.D) && ctrl_pressed ||
		    (keyval == Gdk.Key.F3)) {
			load_latest_snapshot ();

			return true;
		}

		return false;
	}

	private void on_escape_key_pressed () {
		if (is_showing_snapshots)
			on_display_back ();
		else if (can_fullscreen) {
			is_fullscreen = false;
			settings.set_boolean ("fullscreen", false);
		}
	}

	private void create_new_snapshot () {
		runner.pause ();
		runner.try_create_snapshot (false);
		runner.resume ();
		runner.get_display ().grab_focus ();
	}

	private void load_latest_snapshot () {
		var snapshots = runner.get_snapshots ();

		if (snapshots.length == 0)
			return;

		runner.pause ();
		runner.preview_snapshot (snapshots[0]);

		try {
			runner.load_previewed_snapshot ();
		}
		catch (Error e) {
			warning ("Failed to load snapshot: %s", e.message);
		}

		runner.resume ();
		runner.get_display ().grab_focus ();
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (resume_dialog != null)
			return resume_dialog.is_active && resume_dialog.gamepad_button_press_event (event);

		if (resume_failed_dialog != null)
			return resume_failed_dialog.is_active && resume_failed_dialog.gamepad_button_press_event (event);

		if (quit_dialog != null)
			return quit_dialog.is_active && quit_dialog.gamepad_button_press_event (event);

		if (restart_dialog != null)
			return restart_dialog.is_active && restart_dialog.gamepad_button_press_event (event);

		if (!window.is_active || !window.get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		if (runner.gamepad_button_press_event (button))
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
			runner.preview_current_state ();
			is_showing_snapshots = false;

			return;
		}

		back ();
	}

	public void run_game (Game game) {
		// If there is a game already running we have to quit it first
		if (runner != null && !quit_game ())
			return;

		this.game = game;

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
		game_title = game.name;

		// Reset the UI parts depending on the runner to avoid an
		// inconsistent state is case we couldn't retrieve it.
		reset_display_page ();

		runner = try_get_runner (game);
		if (runner == null)
			return;

		can_fullscreen = runner.can_fullscreen;
		header_bar.media_set = runner.media_set;

		runner.crash.connect (message => {
			runner.stop ();
			reset_display_page ();

			if (run_game_cancellable != null)
				run_game_cancellable.cancel ();

			if (quit_game_cancellable != null)
				quit_game_cancellable.cancel ();

			stack.visible_child = error_display;
			is_showing_snapshots = false;
			error_display.game_crashed (game, message);
		});

		update_actions ();

		is_fullscreen = settings.get_boolean ("fullscreen") && can_fullscreen;

		if (!runner.can_resume) {
			start_or_resume (runner, false);
			return;
		}

		var response = prompt_resume_with_cancellable (cancellable);

		if (response == Gtk.ResponseType.NONE)
			return;

		if (!start_or_resume (runner, response == Gtk.ResponseType.ACCEPT))
			prompt_resume_fail_with_cancellable (runner, cancellable);
	}

	private Runner? try_get_runner (Game game) {
		var collection = Application.get_default ().get_collection ();
		var runner = collection.create_runner (game);

		assert (runner != null);

		try {
			runner.prepare ();
		}
		catch (RunnerError e) {
			reset_display_page ();

			stack.visible_child = error_display;
			error_display.running_game_failed (game, e.message);

			return null;
		}

		return runner;
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

	private bool start_or_resume (Runner runner, bool resume) {
		try {
			if (resume)
				runner.load_previewed_snapshot ();

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
			runner = null;
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
		if (runner == null)
			return true;

		runner.pause ();

		if (!runner.is_integrated) {
			// Game does not and will not support snapshots (e.g. Steam games)
			// => Progress cannot be saved so game can be quit safely
			runner.stop ();
			return true;
		}

		if (runner.try_create_snapshot (true) != null) {
			// Progress saved => can quit game safely
			runner.stop ();
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
		if (runner != null)
			runner.resume ();

		return false;
	}

	private void reset_display_page () {
		can_fullscreen = false;
		runner = null;
		header_bar.media_set = null;

		update_actions ();
	}

	[GtkCallback]
	private void on_snapshots_hidden () {
		if (window.is_active) {
			runner.resume ();
			runner.get_display ().grab_focus ();
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
			if (!is_showing_snapshots) {
				runner.resume ();
				runner.get_display ().grab_focus ();
			}
		}
		else if (with_delay)
			focus_out_timeout_id = Timeout.add (FOCUS_OUT_DELAY_MILLISECONDS, on_focus_out_delay_elapsed);
		else
			runner.pause ();
	}

	private bool on_focus_out_delay_elapsed () {
		focus_out_timeout_id = -1;

		if (!can_update_pause ())
			return false;

		if (!window.is_active)
			runner.pause ();

		return false;
	}

	private bool can_update_pause () {
		if (runner == null)
			return false;

		if (run_game_cancellable != null)
			return false;

		if (quit_game_cancellable != null)
			return false;

		if (restart_dialog != null)
			return false;

		return true;
	}

	private void update_actions () {
		var action = action_group.lookup_action ("show-snapshots") as SimpleAction;
		action.set_enabled (runner != null && runner.supports_snapshots);
	}

	private void load_snapshot () {
		try {
			runner.load_previewed_snapshot ();
		}
		catch (Error e) {
			critical ("Failed to load snapshot: %s", e.message);
		}

		is_showing_snapshots = false;
	}

	private void show_snapshots () {
		if (runner != null && runner.is_integrated)
			is_showing_snapshots = true;
	}

	private void restart () {
		if (runner != null && runner.is_integrated) {
			runner.pause ();

			if (runner.try_create_snapshot (true) == null) {
				restart_dialog = new RestartDialog ();
				restart_dialog.transient_for = window;

				var response = restart_dialog.run ();
				restart_dialog.destroy ();
				restart_dialog = null;

				if (response == Gtk.ResponseType.CANCEL || response == Gtk.ResponseType.DELETE_EVENT) {
					runner.resume ();

					return;
				}
			}

			runner.stop ();
			runner = try_get_runner (game);

			try {
				runner.start ();
			}
			catch (Error e) {
				critical ("Couldn't restart: %s", e.message);
			}

			return;
		}

		if (game != null)
			run_game (game);
	}

	private void set_display (Gtk.Widget display) {
		remove_display ();
		display_bin.add (display);
		display.visible = true;
	}

	private void remove_display () {
		var child = display_bin.get_child ();
		if (child != null)
			display_bin.remove (child);
	}

	[GtkCallback]
	private void on_snapshots_list_size_allocate (Gtk.Allocation allocation) {
		display_bin.horizontal_offset = -allocation.width / 2;
	}

	[GtkCallback]
	private void on_header_bar_back () {
		on_display_back ();
	}

	[GtkCallback]
	private void update_fullscreen_box () {
		fullscreen_box.autohide = !header_bar.is_menu_open &&
		                          !is_showing_snapshots;
		fullscreen_box.overlay = is_fullscreen && !is_showing_snapshots;
	}
}
