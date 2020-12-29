// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-view.ui")]
private class Games.DisplayView : Gtk.Box, UiView {
	private const uint FOCUS_OUT_DELAY_MILLISECONDS = 500;

	public signal void back ();

	[GtkChild]
	private Gtk.Stack headerbar_stack;
	[GtkChild]
	private Hdy.HeaderBar ingame_header_bar;
	[GtkChild]
	private Gtk.Button fullscreen;
	[GtkChild]
	private Gtk.Button restore;
	[GtkChild]
	private Gtk.MenuButton secondary_menu_button;
	[GtkChild]
	private Hdy.HeaderBar snapshots_header_bar;
	[GtkChild]
	private MediaMenuButton media_button;
	[GtkChild]
	private InputModeSwitcher input_mode_switcher;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Hdy.StatusPage error_display;
	[GtkChild]
	private Gtk.Button restart_btn;
	[GtkChild]
	private Gtk.Overlay display_overlay;
	[GtkChild]
	private DisplayBin display_bin;
	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private FlashBox flash_box;
	[GtkChild]
	private SnapshotsList snapshots_list;

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
	public bool is_menu_open { get; set; }
	public string game_title { get; set; }

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			if (runner != null)
				runner.snapshot_created.disconnect (flash_box.flash);

			_runner = value;
			remove_display ();

			if (runner == null)
				return;

			stack.visible_child = display_overlay;

			var display = runner.get_display ();
			set_display (display);

			snapshots_list.runner = value;
			input_mode_switcher.runner = value;

			if (runner != null)
				extra_widget = runner.get_extra_widget ();
			else
				extra_widget = null;

			secondary_menu_button.visible = runner != null && runner.is_integrated;

			runner.snapshot_created.connect (flash_box.flash);
		}
	}

	private HeaderBarWidget _extra_widget;
	private HeaderBarWidget extra_widget {
		get { return _extra_widget; }
		set {
			if (extra_widget == value)
				return;

			if (extra_widget != null) {
				extra_widget.disconnect (extra_widget_notify_block_autohide_id);
				ingame_header_bar.remove (extra_widget);
				extra_widget_notify_block_autohide_id = 0;
			}

			_extra_widget = value;

			if (extra_widget != null) {
				extra_widget_notify_block_autohide_id = extra_widget.notify["block-autohide"].connect (update_fullscreen_box);
				ingame_header_bar.pack_end (extra_widget);
			}
		}
	}

	private Settings settings;

	private Cancellable run_game_cancellable;
	private Cancellable quit_game_cancellable;

	private Gtk.MessageDialog resume_dialog;
	private Gtk.MessageDialog resume_failed_dialog;
	private Gtk.MessageDialog quit_dialog;
	private Gtk.MessageDialog restart_dialog;

	private ulong extra_widget_notify_block_autohide_id;

	private Game game;

	private SimpleActionGroup action_group;
	private const ActionEntry[] action_entries = {
		{ "load-snapshot",  load_snapshot  },
		{ "show-snapshots", show_snapshots },
		{ "restart",        restart        },
	};

	construct {
		settings = new Settings ("org.gnome.Games");

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

		if (is_showing_snapshots &&
		    snapshots_list.on_key_press_event (keyval, event.state & default_modifiers))
			return true;

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
			return handle_dialog_gamepad_button_press_event (resume_dialog, event);

		if (resume_failed_dialog != null)
			return handle_dialog_gamepad_button_press_event (resume_failed_dialog, event);

		if (quit_dialog != null)
			return handle_dialog_gamepad_button_press_event (quit_dialog, event);

		if (restart_dialog != null)
			return handle_dialog_gamepad_button_press_event (restart_dialog, event);

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

	public async void run_game (Game game) {
		// If there is a game already running we have to quit it first
		if (runner != null && !yield quit_game ())
			return;

		this.game = game;

		if (run_game_cancellable != null)
			run_game_cancellable.cancel ();

		var cancellable = new Cancellable ();
		run_game_cancellable = cancellable;

		yield run_game_with_cancellable (game, cancellable);

		// Only reset the cancellable if another one didn't replace it.
		if (run_game_cancellable == cancellable)
			run_game_cancellable = null;
	}

	private async void run_game_with_cancellable (Game game, Cancellable cancellable) {
		game_title = game.name;

		// Reset the UI parts depending on the runner to avoid an
		// inconsistent state is case we couldn't retrieve it.
		reset_display_page ();

		runner = try_get_runner (game);
		if (runner == null)
			return;

		can_fullscreen = runner.can_fullscreen;
		media_button.media_set = runner.media_set;

		runner.crash.connect (message => {
			runner.stop ();
			reset_display_page ();

			if (run_game_cancellable != null)
				run_game_cancellable.cancel ();

			if (quit_game_cancellable != null)
				quit_game_cancellable.cancel ();

			stack.visible_child = error_display;
			is_showing_snapshots = false;

			error_display.title = _("Oops! The game crashed unexpectedly");
			error_display.description = message;
			restart_btn.show ();
		});

		update_actions ();

		is_fullscreen = settings.get_boolean ("fullscreen") && can_fullscreen;

		if (!runner.can_resume) {
			start_or_resume (runner, false);
			return;
		}

		var response = yield prompt_resume_with_cancellable (cancellable);

		if (response == Gtk.ResponseType.NONE)
			return;

		if (!start_or_resume (runner, response == Gtk.ResponseType.ACCEPT))
			yield prompt_resume_fail_with_cancellable (runner, cancellable);
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

			error_display.title = _("Oops! Unable to run the game");
			error_display.description = e.message;
			restart_btn.hide ();

			return null;
		}

		return runner;
	}

	private async Gtk.ResponseType prompt_resume_with_cancellable (Cancellable cancellable) {
		if (resume_dialog != null)
			return Gtk.ResponseType.NONE;

		resume_dialog = new Gtk.MessageDialog (
			window,
			Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
			Gtk.MessageType.QUESTION,
			Gtk.ButtonsType.NONE,
			"%s",
			_("Resume last game?")
		);

		resume_dialog.add_button (_("Restart"), Gtk.ResponseType.CANCEL);
		resume_dialog.add_button (_("Resume"), Gtk.ResponseType.ACCEPT);
		resume_dialog.set_default_response (Gtk.ResponseType.ACCEPT);

		cancellable.cancelled.connect (() => {
			resume_dialog.destroy ();
			resume_dialog = null;
		});

		var response = yield run_dialog_async (resume_dialog);

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

	private async void prompt_resume_fail_with_cancellable (Runner runner, Cancellable cancellable) {
		if (resume_failed_dialog != null)
			return;

		resume_failed_dialog = new Gtk.MessageDialog (
			window,
			Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
			Gtk.MessageType.QUESTION,
			Gtk.ButtonsType.CANCEL,
			"%s",
			_("Resume last game?")
		);

		resume_failed_dialog.add_button (C_("Resuming a game failed dialog", "Reset"), Gtk.ResponseType.ACCEPT);

		cancellable.cancelled.connect (() => {
			resume_failed_dialog.destroy ();
			resume_failed_dialog = null;
		});

		var response = yield run_dialog_async (resume_failed_dialog);

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

	public async bool quit_game () {
		if (run_game_cancellable != null)
			run_game_cancellable.cancel ();

		if (quit_game_cancellable != null)
			quit_game_cancellable.cancel ();

		var cancellable = new Cancellable ();
		quit_game_cancellable = cancellable;

		var result = yield quit_game_with_cancellable (cancellable);

		// Only reset the cancellable if another one didn't replace it.
		if (quit_game_cancellable == cancellable)
			quit_game_cancellable = null;

		return result;
	}

	private async bool quit_game_with_cancellable (Cancellable cancellable) {
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

		quit_dialog = new Gtk.MessageDialog (
			window,
			Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
			Gtk.MessageType.QUESTION,
			Gtk.ButtonsType.CANCEL,
			"%s",
			_("Are you sure you want to quit?")
		);

		quit_dialog.format_secondary_text ("%s", _("All unsaved progress will be lost."));

		var button = quit_dialog.add_button (_("Quit"), Gtk.ResponseType.ACCEPT);
		button.get_style_context ().add_class ("destructive-action");

		cancellable.cancelled.connect (() => {
			quit_dialog.destroy ();
			quit_dialog = null;
		});

		var response = yield run_dialog_async (quit_dialog);

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
		media_button.media_set = null;
		secondary_menu_button.visible = false;
		extra_widget = null;

		update_actions ();
	}

	[GtkCallback]
	private void on_snapshots_hidden () {
		if (window.is_active) {
			runner.resume ();
			runner.get_display ().grab_focus ();
		}
	}

	public void update_pause () {
		if (!can_update_pause ())
			return;

		if (window.is_active) {
			if (!is_showing_snapshots) {
				runner.resume ();
				runner.get_display ().grab_focus ();
			}
		}
		else
			runner.pause ();
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
		restart_internal.begin ();
	}

	private async void restart_internal () {
		if (runner == null || !runner.is_integrated) {
			yield run_game (game);

			return;
		}

		runner.pause ();

		if (runner.try_create_snapshot (true) == null) {
			restart_dialog = new Gtk.MessageDialog (
				window,
				Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.MessageType.QUESTION,
				Gtk.ButtonsType.CANCEL,
				"%s",
				_("Are you sure you want to restart?")
			);

			restart_dialog.format_secondary_text ("%s", _("All unsaved progress will be lost."));

			var button = restart_dialog.add_button (_("Restart"), Gtk.ResponseType.ACCEPT);
			button.get_style_context ().add_class ("destructive-action");

			var response = yield run_dialog_async (restart_dialog);

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
	private void update_fullscreen_box () {
		var is_menu_open = media_button.active ||
		                   secondary_menu_button.active ||
		                   (extra_widget != null && extra_widget.block_autohide);

		fullscreen_box.autohide = !is_menu_open &&
		                          !is_showing_snapshots;
		fullscreen_box.overlay = is_fullscreen && !is_showing_snapshots;
	}

	[GtkCallback]
	private void on_fullscreen_changed () {
		fullscreen.visible = can_fullscreen && !is_fullscreen;
		restore.visible = can_fullscreen && is_fullscreen;

		update_fullscreen_box ();
	}

	[GtkCallback]
	private void on_showing_snapshots_changed () {
		update_fullscreen_box ();

		if (is_showing_snapshots)
			headerbar_stack.visible_child = snapshots_header_bar;
		else
			headerbar_stack.visible_child = ingame_header_bar;
	}

	[GtkCallback]
	private void on_back_clicked () {
		on_display_back ();
	}

	[GtkCallback]
	private void on_fullscreen_clicked () {
		is_fullscreen = true;
		settings.set_boolean ("fullscreen", true);
	}

	[GtkCallback]
	private void on_restore_clicked () {
		is_fullscreen = false;
		settings.set_boolean ("fullscreen", false);
	}

	private bool handle_dialog_gamepad_button_press_event (Gtk.Dialog dialog, Manette.Event event) {
		if (!visible)
			return false;

		if (!dialog.is_active)
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_A:
			dialog.response (Gtk.ResponseType.ACCEPT);

			return true;
		case EventCode.BTN_B:
			dialog.response (Gtk.ResponseType.CANCEL);

			return true;
		default:
			return false;
		}
	}

	private async Gtk.ResponseType run_dialog_async (Gtk.Dialog dialog) {
		var response = Gtk.ResponseType.CANCEL;

		dialog.response.connect (r => {
			response = (Gtk.ResponseType) r;

			run_dialog_async.callback ();
		});

		dialog.present ();

		yield;

		return response;
	}
}
