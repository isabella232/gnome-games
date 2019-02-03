// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/application-window.ui")]
private class Games.ApplicationWindow : Gtk.ApplicationWindow {
	private const uint WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS = 500;
	private const uint FOCUS_OUT_DELAY_MILLISECONDS = 500;

	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	private UiState _ui_state;
	public UiState ui_state {
		get { return _ui_state; }
		set {
			if (value == ui_state)
				return;

			_ui_state = value;

			switch (ui_state) {
			case UiState.COLLECTION:
				content_box.visible_child = collection_box;
				header_bar.visible_child = collection_header_bar;

				is_fullscreen = false;

				if (display_box.runner != null) {
					display_box.runner.stop ();
					display_box.runner = null;
				}

				break;
			case UiState.DISPLAY:
				content_box.visible_child = display_box;
				header_bar.visible_child = display_header_bar;

				search_mode = false;

				break;
			}

			konami_code.reset ();
		}
	}

	private bool _is_fullscreen;
	public bool is_fullscreen {
		get { return _is_fullscreen; }
		set {
			_is_fullscreen = value && (ui_state == UiState.DISPLAY);

			if (_is_fullscreen)
				fullscreen ();
			else
				unfullscreen ();
		}
	}

	private bool _search_mode;
	public bool search_mode {
		get { return _search_mode; }
		set { _search_mode = value && (ui_state == UiState.COLLECTION); }
	}

	public bool is_collection_empty { get; set; }

	public bool loading_notification { get; set; }

	[GtkChild]
	private Gtk.Stack content_box;
	[GtkChild]
	private CollectionBox collection_box;
	[GtkChild]
	private DisplayBox display_box;

	[GtkChild]
	private Gtk.Stack header_bar;
	[GtkChild]
	private CollectionHeaderBar collection_header_bar;
	[GtkChild]
	private DisplayHeaderBar display_header_bar;

	private Settings settings;

	private Binding box_search_binding;
	private Binding box_fullscreen_binding;
	private Binding box_empty_collection_binding;
	private Binding header_bar_search_binding;
	private Binding header_bar_fullscreen_binding;
	private Binding header_bar_empty_collection_binding;
	private Binding loading_notification_binding;

	private Cancellable run_game_cancellable;
	private Cancellable quit_game_cancellable;

	private ResumeDialog resume_dialog;
	private ResumeFailedDialog resume_failed_dialog;
	private QuitDialog quit_dialog;

	private long window_size_update_timeout;
	private long focus_out_timeout_id;

	private uint inhibit_cookie;
	private Gtk.ApplicationInhibitFlags inhibit_flags;

	private KonamiCode konami_code;

	public ApplicationWindow (ListModel collection) {
		collection_box.collection = collection;
		collection.items_changed.connect (() => {
			is_collection_empty = collection.get_n_items () == 0;
		});
		is_collection_empty = collection.get_n_items () == 0;
	}

	construct {
		settings = new Settings ("org.gnome.Games");

		int width, height;
		settings.get ("window-size", "(ii)", out width, out height);
		var geometry = get_geometry ();
		if (geometry != null) {
			width = int.min (width, geometry.width);
			height = int.min (height, geometry.height);
		}
		resize (width, height);

		if (settings.get_boolean ("window-maximized"))
			maximize ();

		box_search_binding = bind_property ("search-mode", collection_box, "search-mode",
		                                    BindingFlags.BIDIRECTIONAL);
		loading_notification_binding = bind_property ("loading-notification", collection_box, "loading-notification",
		                                              BindingFlags.DEFAULT);
		header_bar_search_binding = bind_property ("search-mode", collection_header_bar, "search-mode",
		                                           BindingFlags.BIDIRECTIONAL);

		box_fullscreen_binding = bind_property ("is-fullscreen", display_box, "is-fullscreen",
		                                        BindingFlags.BIDIRECTIONAL);
		header_bar_fullscreen_binding = bind_property ("is-fullscreen", display_header_bar, "is-fullscreen",
		                                               BindingFlags.BIDIRECTIONAL);

		box_empty_collection_binding = bind_property ("is-collection-empty", collection_box, "is-collection-empty",
		                                              BindingFlags.BIDIRECTIONAL);
		header_bar_empty_collection_binding = bind_property ("is-collection-empty", collection_header_bar, "is-collection-empty",
		                                                     BindingFlags.BIDIRECTIONAL);

		konami_code = new KonamiCode (this);
		konami_code.code_performed.connect (on_konami_code_performed);

		collection_header_bar.viewstack = collection_box.viewstack;

		window_size_update_timeout = -1;
		focus_out_timeout_id = -1;
		inhibit_cookie = 0;
		inhibit_flags = 0;

		show_menubar = false; // Essential, see bug #771683

		if (Config.PROFILE == "Devel")
			get_style_context ().add_class ("devel");

		set_help_overlay (new ShortcutsWindow ());
	}

	public void run_game (Game game) {
		// If there is a game already running we have to quit it first
		if (display_box.runner != null && !quit_game())
			return;

		if (run_game_cancellable != null)
			run_game_cancellable.cancel ();

		var cancellable = new Cancellable ();
		run_game_cancellable = cancellable;

		run_game_with_cancellable (game, cancellable);

		// Only reset the cancellable if another one didn't replace it.
		if (run_game_cancellable == cancellable)
			run_game_cancellable = null;

		inhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
	}

	public bool quit_game () {
		// If the window have been deleted/hidden we probably don't want to
		// prompt the user.
		if (!visible)
			return true;

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

	public override void size_allocate (Gtk.Allocation allocation) {
		base.size_allocate (allocation);

		if (window_size_update_timeout == -1 && !is_maximized)
			window_size_update_timeout = Timeout.add (WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS, store_window_size);
	}

	[GtkCallback]
	public bool on_delete_event () {
		return !quit_game ();
	}

	[GtkCallback]
	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.q || event.keyval == Gdk.Key.Q) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {
			if (!quit_game ())
				return false;

			destroy ();

			return true;
		}

		return handle_collection_key_event (event) || handle_display_key_event (event);
	}

	[GtkCallback]
	public bool on_button_pressed (Gdk.EventButton event) {
		// Mouse button 8 is the navigation previous button
		if (event.button == 8) {
			if (ui_state != UiState.DISPLAY)
				return false;

			on_display_back ();
			return true;
		}

		return false;
	}

	[GtkCallback]
	public bool on_window_state_event (Gdk.EventWindowState event) {
		var is_maximized = (bool) (event.new_window_state & Gdk.WindowState.MAXIMIZED);
		settings.set_boolean ("window-maximized", is_maximized);

		is_fullscreen = (bool) (event.new_window_state & Gdk.WindowState.FULLSCREEN);
		update_pause (false);

		if (!(bool) (event.changed_mask & Gdk.WindowState.FOCUSED))
			return false;

		var focused = (bool) (event.new_window_state & Gdk.WindowState.FOCUSED);
		var playing = (ui_state == UiState.DISPLAY);

		if (focused && playing)
			inhibit (Gtk.ApplicationInhibitFlags.IDLE);

		if (!focused)
			uninhibit (Gtk.ApplicationInhibitFlags.IDLE);

		return false;
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		switch (ui_state) {
		case UiState.COLLECTION:
			return is_active && collection_box.gamepad_button_press_event (event);
		case UiState.DISPLAY:
			if (resume_dialog != null)
				return resume_dialog.is_active && resume_dialog.gamepad_button_press_event (event);

			if (resume_failed_dialog != null)
				return resume_failed_dialog.is_active && resume_failed_dialog.gamepad_button_press_event (event);

			if (quit_dialog != null)
				return quit_dialog.is_active && quit_dialog.gamepad_button_press_event (event);

			if (!is_active || !get_mapped ())
				return false;

			uint16 button;
			if (!event.get_button (out button))
				return false;

			switch (button) {
			case EventCode.BTN_MODE:
				ui_state = UiState.COLLECTION;

				return true;
			default:
				return false;
			}
		default:
			return false;
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		switch (ui_state) {
		case UiState.COLLECTION:
			return is_active && collection_box.gamepad_button_release_event (event);
		default:
			return false;
		}
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		switch (ui_state) {
		case UiState.COLLECTION:
			return is_active && collection_box.gamepad_absolute_axis_event (event);
		default:
			return false;
		}
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		run_game (game);
	}

	[GtkCallback]
	private void on_display_back () {
		if (quit_game ())
			ui_state = UiState.COLLECTION;

		uninhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
	}

	private void run_game_with_cancellable (Game game, Cancellable cancellable) {
		display_header_bar.game_title = game.name;
		display_box.header_bar.game_title = game.name;
		ui_state = UiState.DISPLAY;

		// Reset the UI parts depending on the runner to avoid an
		// inconsistent state is case we couldn't retrieve it.
		reset_display_page ();

		var runner = try_get_runner (game);
		if (runner == null)
			return;

		display_header_bar.can_fullscreen = runner.can_fullscreen;
		display_box.header_bar.can_fullscreen = runner.can_fullscreen;
		display_header_bar.runner = runner;
		display_box.runner = runner;
		display_header_bar.media_set = runner.media_set;
		display_box.header_bar.media_set = runner.media_set;

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
		try {
			var runner = game.get_runner ();
			string error_message;
			if (runner.check_is_valid (out error_message))
				return runner;

			reset_display_page ();
			display_box.display_running_game_failed (game, error_message);

			return null;
		}
		catch (Error e) {
			warning (e.message);
			reset_display_page ();
			display_box.display_running_game_failed (game, _("An unexpected error occurred."));

			return null;
		}
	}

	private Gtk.ResponseType prompt_resume_with_cancellable (Cancellable cancellable) {
		if (resume_dialog != null)
			return Gtk.ResponseType.NONE;

		resume_dialog = new ResumeDialog ();
		resume_dialog.transient_for = this;

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
				display_box.runner.resume ();
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
		resume_failed_dialog.transient_for = this;

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
			display_box.runner = null;
			ui_state = UiState.COLLECTION;

			return;
		}

		try {
			runner.start ();
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	public bool quit_game_with_cancellable (Cancellable cancellable) {
		if (display_box.runner == null)
			return true;

		display_box.runner.pause ();

		if (display_box.runner.can_quit_safely) {
			display_box.runner.stop();

			return true;
		}

		if (quit_dialog != null)
			return false;

		quit_dialog = new QuitDialog ();
		quit_dialog.transient_for = this;

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
		if (display_box.runner != null)
			try {
				display_box.runner.resume ();
			}
			catch (Error e) {
				warning (e.message);
			}

		return false;
	}

	[GtkCallback]
	private void on_active_changed () {
		update_pause (true);
	}

	private Gdk.Rectangle? get_geometry () {
		var display = get_display ();
		if (display == null)
			return null;

		var window = get_window ();
		if (window == null)
			return null;

		var monitor = display.get_monitor_at_window (window);
		if (monitor == null)
			return null;

		return monitor.geometry;
	}

	private bool store_window_size () {
		var geometry = get_geometry ();
		if (geometry == null)
			return false;

		int width = 0;
		int height = 0;

		get_size (out width, out height);

		width = int.min (width, geometry.width);
		height = int.min (height, geometry.height);

		settings.set ("window-size", "(ii)", width, height);

		Source.remove ((uint) window_size_update_timeout);
		window_size_update_timeout = -1;

		return false;
	}

	private void update_pause (bool with_delay) {
		if (focus_out_timeout_id != -1) {
			Source.remove ((uint) focus_out_timeout_id);
			focus_out_timeout_id = -1;
		}

		if (!can_update_pause ())
			return;

		if (is_active)
			try {
				display_box.runner.resume ();
			}
			catch (Error e) {
				warning (e.message);
			}
		else if (with_delay)
			focus_out_timeout_id = Timeout.add (FOCUS_OUT_DELAY_MILLISECONDS, on_focus_out_delay_elapsed);
		else
			display_box.runner.pause ();
	}

	private bool on_focus_out_delay_elapsed () {
		focus_out_timeout_id = -1;

		if (!can_update_pause ())
			return false;

		if (!is_active)
			display_box.runner.pause ();

		return false;
	}

	private bool can_update_pause () {
		if (ui_state != UiState.DISPLAY)
			return false;

		if (display_box.runner == null)
			return false;

		if (run_game_cancellable != null)
			return false;

		if (quit_game_cancellable != null)
			return false;

		return true;
	}

	private bool handle_collection_key_event (Gdk.EventKey event) {
		if (ui_state != UiState.COLLECTION)
			return false;

		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.f || event.keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		return collection_box.search_bar_handle_event (event);
	}

	private bool handle_display_key_event (Gdk.EventKey event) {
		if (ui_state != UiState.DISPLAY)
			return false;

		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.f || event.keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK &&
		    display_header_bar.can_fullscreen) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (event.keyval == Gdk.Key.F11 && display_header_bar.can_fullscreen) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (event.keyval == Gdk.Key.Escape && display_header_bar.can_fullscreen) {
			is_fullscreen = false;
			settings.set_boolean ("fullscreen", false);

			return true;
		}

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((get_direction () == Gtk.TextDirection.LTR) && event.keyval == Gdk.Key.Left) ||
		     ((get_direction () == Gtk.TextDirection.RTL) && event.keyval == Gdk.Key.Right))) {
			on_display_back ();

			return true;
		}

		return false;
	}

	private void inhibit (Gtk.ApplicationInhibitFlags flags) {
		if ((inhibit_flags & flags) == flags)
			return;

		Gtk.ApplicationInhibitFlags new_flags = (inhibit_flags | flags);
		uint new_cookie = application.inhibit (this, new_flags, _("Playing a game"));

		if (inhibit_cookie != 0)
			application.uninhibit (inhibit_cookie);

		inhibit_cookie = new_cookie;
		inhibit_flags = new_flags;
	}

	private void uninhibit (Gtk.ApplicationInhibitFlags flags) {
		if ((inhibit_flags & flags) == 0)
			return;

		Gtk.ApplicationInhibitFlags new_flags = (inhibit_flags & ~flags);
		uint new_cookie = 0;

		if ((bool) new_flags)
			new_cookie = application.inhibit (this, new_flags, _("Playing a game"));

		if (inhibit_cookie != 0)
			application.uninhibit (inhibit_cookie);

		inhibit_cookie = new_cookie;
		inhibit_flags = new_flags;
	}

	private void reset_display_page () {
		display_header_bar.can_fullscreen = false;
		display_box.header_bar.can_fullscreen = false;
		display_header_bar.runner = null;
		display_box.runner = null;
		display_header_bar.media_set = null;
		display_box.header_bar.media_set = null;
	}

	private void on_konami_code_performed () {
		if (ui_state != UiState.COLLECTION)
			return;

		try {
			Gtk.show_uri_on_window (this, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}
}
