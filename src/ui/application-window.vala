// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/application-window.ui")]
private class Games.ApplicationWindow : Hdy.ApplicationWindow {
	private const uint WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS = 500;

	private UiView _current_view;
	public UiView current_view {
		get { return _current_view; }
		set {
			if (value == current_view)
				return;

			if (current_view != null)
				current_view.is_view_active = false;

			_current_view = value;

			stack.visible_child = current_view.content_box;

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

	[GtkChild]
	private Gtk.Stack stack;

	private CollectionView collection_view;
	private DisplayView display_view;

	private Settings settings;

	private long window_size_update_timeout;

	private uint inhibit_cookie;
	private Gtk.ApplicationInhibitFlags inhibit_flags;

	public GameModel game_model { get; construct; }

	public ApplicationWindow (Application application, GameModel game_model) {
		Object (application: application, game_model: game_model);

		current_view = collection_view;
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

		collection_view = new CollectionView (this, game_model);
		display_view = new DisplayView (this);

		stack.add (collection_view.content_box);
		stack.add (display_view.content_box);

		collection_view.game_activated.connect (on_game_activated);
		display_view.back.connect (on_display_back);

		bind_property ("loading-notification", collection_view,
                       "loading-notification", BindingFlags.DEFAULT);

		bind_property ("is-fullscreen", display_view,
		               "is-fullscreen", BindingFlags.BIDIRECTIONAL);

		window_size_update_timeout = -1;
		inhibit_cookie = 0;
		inhibit_flags = 0;

		if (Config.PROFILE == "Devel")
			get_style_context ().add_class ("devel");

		set_help_overlay (new ShortcutsWindow ());
	}

	public void run_search (string query) {
		if (current_view != collection_view)
			return;

		collection_view.run_search (query);
	}

	public void show_error (string error_message) {
		collection_view.show_error (error_message);
	}

	public void run_game (Game game) {
		if (current_view != collection_view)
			return;

		current_view = display_view;
		display_view.run_game (game);

		inhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
	}

	public bool quit_game () {
		// If the window have been deleted/hidden we probably don't want to
		// prompt the user.
		if (!visible)
			return true;

		return display_view.quit_game ();
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
			display_view.update_pause (false);

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

	private void on_game_activated (Game game) {
		run_game (game);
	}

	private void on_display_back () {
		if (quit_game ())
			current_view = collection_view;

		uninhibit (Gtk.ApplicationInhibitFlags.IDLE | Gtk.ApplicationInhibitFlags.LOGOUT);
	}

	[GtkCallback]
	private void on_active_changed () {
		if (current_view == display_view)
			display_view.update_pause (true);
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
