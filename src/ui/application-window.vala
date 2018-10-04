// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/application-window.ui")]
private class Games.ApplicationWindow : Gtk.ApplicationWindow {
	private const uint WINDOW_SIZE_UPDATE_DELAY_MILLISECONDS = 500;

	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	private ApplicationView _current_view;
	public ApplicationView current_view {
		get { return _current_view; }
		set {
			if (value == current_view)
				return;

			if (current_view != null)
				current_view.is_view_active = false;

			_current_view = value;

			content_box.visible_child = current_view;
			header_bar.visible_child = current_view.titlebar;

			if (current_view != null)
				current_view.is_view_active = true;

			konami_code.reset ();
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
	private Gtk.Stack content_box;
	[GtkChild]
	private CollectionView collection_view;
	[GtkChild]
	private DisplayView display_view;

	[GtkChild]
	private Gtk.Stack header_bar;

	private Settings settings;

	private Binding fullscreen_binding;
	private Binding loading_notification_binding;

	private long window_size_update_timeout;

	private uint inhibit_cookie;
	private Gtk.ApplicationInhibitFlags inhibit_flags;

	private KonamiCode konami_code;

	public ApplicationWindow (ListModel collection) {
		collection_view.window = this;
		display_view.window = this;
		collection_view.collection = collection;
	}

	construct {
		header_bar.add (collection_view.titlebar);
		header_bar.add (display_view.titlebar);
		current_view = collection_view;

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

		loading_notification_binding = bind_property ("loading-notification",
		                                              collection_view,
		                                              "loading-notification",
		                                              BindingFlags.DEFAULT);

		fullscreen_binding = bind_property ("is-fullscreen", display_view,
		                                    "is-fullscreen",
		                                    BindingFlags.BIDIRECTIONAL);

		konami_code = new KonamiCode (this);
		konami_code.code_performed.connect (on_konami_code_performed);

		window_size_update_timeout = -1;
		inhibit_cookie = 0;
		inhibit_flags = 0;

		show_menubar = false; // Essential, see bug #771683

		if (Config.PROFILE == "Devel")
			get_style_context ().add_class ("devel");
	}

	public void run_game (Game game) {
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
			return false;

		var focused = (bool) (event.new_window_state & Gdk.WindowState.FOCUSED);
		var playing = (current_view == display_view);

		if (focused && playing)
			inhibit (Gtk.ApplicationInhibitFlags.IDLE);

		if (!focused)
			uninhibit (Gtk.ApplicationInhibitFlags.IDLE);

		return false;
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
		run_game (game);
	}

	[GtkCallback]
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

	private void on_konami_code_performed () {
		if (current_view != collection_view)
			return;

		try {
			Gtk.show_uri_on_window (this, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}
}
