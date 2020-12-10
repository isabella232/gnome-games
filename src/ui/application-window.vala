// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/application-window.ui")]
private class Games.ApplicationWindow : Hdy.ApplicationWindow {
	private const uint WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS = 500;

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private CollectionView collection_view;
	[GtkChild]
	private DisplayView display_view;

	private UiView _current_view;
	public UiView current_view {
		get { return _current_view; }
		set {
			if (value == current_view)
				return;

			if (current_view != null)
				current_view.is_view_active = false;

			_current_view = value;

			stack.visible_child = current_view;

			if (current_view != null)
				current_view.is_view_active = true;

			var app = application as Application;
			assert (app != null);

			app.set_pause_loading (current_view != collection_view);
		}
	}

	private bool _is_fullscreen;
	public bool is_fullscreen {
		get { return _is_fullscreen; }
		set {
			_is_fullscreen = value && (current_view == display_view);

			if (_is_fullscreen)
				fullscreen ();
			else
				unfullscreen ();
		}
	}

	public bool loading_notification { get; set; }

	private Settings settings;

	private long window_size_update_timeout;

	private uint inhibit_cookie;
	private Gtk.ApplicationInhibitFlags inhibit_flags;

	public GameModel game_model { get; construct; }
	public CollectionModel collection_model { get; construct; }

	private bool confirm_exit;

	public ApplicationWindow (Application application, GameModel game_model, CollectionModel collection_model) {
		Object (application: application, game_model: game_model, collection_model: collection_model);

		current_view = collection_view;
	}

	construct {
		settings = new Settings ("org.gnome.Games");

		collection_view.game_model = game_model;
		collection_view.collection_model = collection_model;

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

		window_size_update_timeout = -1;
		inhibit_cookie = 0;
		inhibit_flags = 0;

		if (Config.PROFILE == "Devel")
			get_style_context ().add_class ("devel");

		init_help_overlay ();
	}

	private void init_help_overlay () {
		var builder = new Gtk.Builder.from_resource ("/org/gnome/Games/ui/help-overlay.ui");
		var shortcuts_window = builder.get_object ("help_overlay") as Gtk.ShortcutsWindow;
		var shortcut = builder.get_object ("general_shortcut_alt_left") as Gtk.ShortcutsShortcut;

		shortcuts_window.direction_changed.connect (() => {
			shortcut.accelerator = get_alt_left_right ();
		});
		shortcut.accelerator = get_alt_left_right ();

		set_help_overlay (shortcuts_window);
	}

	private string get_alt_left_right () {
		return get_direction () == Gtk.TextDirection.LTR ? "<alt>Left" : "<alt>Right";
	}

	public void run_search (string query) {
		if (current_view != collection_view)
			return;

		collection_view.run_search (query);
	}

	public void show_error (string error_message) {
		collection_view.show_error (error_message);
	}

	public async void run_game (Game game) {
		if (current_view != collection_view)
			return;

		current_view = display_view;
		yield display_view.run_game (game);

		inhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
	}

	public async bool quit_game () {
		// If the window have been deleted/hidden we probably don't want to
		// prompt the user.
		if (!visible)
			return true;

		return yield display_view.quit_game ();
	}

	public override void size_allocate (Gtk.Allocation allocation) {
		base.size_allocate (allocation);

		if (window_size_update_timeout == -1 && !is_maximized)
			window_size_update_timeout = Timeout.add (WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS, store_window_size);
	}

	[GtkCallback]
	public bool on_delete_event () {
		if (confirm_exit)
			return true;

		quit_game.begin ((obj, res) => {
			if (!quit_game.end (res))
				return;

			confirm_exit = true;

			close ();
		});

		return false;
	}

	[GtkCallback]
	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);

		if ((keyval == Gdk.Key.q || keyval == Gdk.Key.Q) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {

			quit_game.begin ((obj, res) => {
				if (!quit_game.end (res))
					return;

				destroy ();
			});

			return true;
		}

		return current_view.on_key_pressed (event);
	}

	[GtkCallback]
	public bool on_button_pressed (Gdk.EventButton event) {
		return current_view.on_button_pressed (event);
	}

	[GtkCallback]
	public bool on_window_state_event (Gdk.EventWindowState event) {
		var is_maximized = (bool) (event.new_window_state & Gdk.WindowState.MAXIMIZED);
		settings.set_boolean ("window-maximized", is_maximized);

		is_fullscreen = (bool) (event.new_window_state & Gdk.WindowState.FULLSCREEN);
		if (current_view == display_view)
			display_view.update_pause ();

		if (!(bool) (event.changed_mask & Gdk.WindowState.FOCUSED))
			return true;

		var focused = (bool) (event.new_window_state & Gdk.WindowState.FOCUSED);
		var playing = (current_view == display_view);

		if (focused && playing)
			inhibit (Gtk.ApplicationInhibitFlags.IDLE);

		if (!focused)
			uninhibit (Gtk.ApplicationInhibitFlags.IDLE);

		return true;
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return current_view.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (current_view == collection_view)
			return collection_view.gamepad_button_release_event (event);

		return false;
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (current_view == collection_view)
			return collection_view.gamepad_absolute_axis_event (event);

		return false;
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		run_game.begin (game);
	}

	[GtkCallback]
	private void on_display_back () {
		quit_game.begin ((obj, res) => {
			if (quit_game.end (res))
				current_view = collection_view;

			uninhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
		});
	}

	[GtkCallback]
	private void on_active_changed () {
		if (current_view == display_view)
			display_view.update_pause ();
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

	private void inhibit (Gtk.ApplicationInhibitFlags flags) {
		if ((inhibit_flags & flags) == flags)
			return;

		Gtk.ApplicationInhibitFlags new_flags = (inhibit_flags | flags);
		/* Translators: This is displayed if the user tries to log out of his
		 * GNOME session, shutdown, or reboot while Games is running */
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
			/* Translators: This is displayed if the user tries to log out of his
		 	 * GNOME session, shutdown, or reboot while Games is running */
			new_cookie = application.inhibit (this, new_flags, _("Playing a game"));

		if (inhibit_cookie != 0)
			application.uninhibit (inhibit_cookie);

		inhibit_cookie = new_cookie;
		inhibit_flags = new_flags;
	}
}
