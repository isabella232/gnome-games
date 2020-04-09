// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-view.ui")]
private class Games.CollectionView : Gtk.Box, UiView {
	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	public signal void game_activated (Game game);

	[GtkChild]
	private ErrorInfoBar error_info_bar;
	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private EmptySearch empty_search;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private PlatformsView platform_view;
	[GtkChild]
	private Gtk.Stack empty_stack;
	[GtkChild (name = "viewstack")]
	private Gtk.Stack _viewstack;
	[GtkChild]
	private Hdy.ViewSwitcherBar view_switcher_bar;
	[GtkChild]
	private CollectionHeaderBar header_bar;
	[GtkChild]
	private Hdy.SwipeGroup swipe_group;

	public Gtk.Widget content_box {
		get { return this; }
	}

	public Gtk.Stack viewstack {
		get { return _viewstack; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active)
				search_mode = false;

			konami_code.reset ();
		}
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (_is_collection_empty)
				empty_stack.visible_child = empty_collection;
			else
				empty_stack.visible_child = viewstack;
		}
	}

	public string[] filtering_terms;
	public string filtering_text {
		 set {
			if (value == null)
				filtering_terms = null;
			else
				filtering_terms = value.split (" ");

			platform_view.set_filter (filtering_terms);
			collection_view.set_filter (filtering_terms);
		}
	}

	public Gtk.Window window { get; construct; }
	public GameModel game_model { get; construct; }

	public bool loading_notification { get; set; }
	public bool search_mode { get; set; }

	public bool is_folded { get; set; }
	public bool is_showing_bottom_bar { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }

	private KonamiCode konami_code;

	construct {
		var icon_name = Config.APPLICATION_ID + "-symbolic";
		viewstack.child_set (collection_view, "icon-name", icon_name);

		collection_view.game_model = game_model;
		platform_view.game_model = game_model;

		swipe_group.add_swipeable (platform_view.get_leaflet ());

		is_collection_empty = game_model.get_n_items () == 0;
		game_model.items_changed.connect (() => {
			is_collection_empty = game_model.get_n_items () == 0;
		});

		bind_property ("viewstack", header_bar,
		               "viewstack", BindingFlags.SYNC_CREATE);

		bind_property ("search-mode", header_bar,
		               "search-mode", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-collection-empty", header_bar,
		               "is-collection-empty", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

		bind_property ("is-folded", header_bar,
		               "is-folded", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-showing-bottom-bar", header_bar,
		               "is-showing-bottom-bar", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-subview-open", header_bar,
		               "is-subview-open", BindingFlags.BIDIRECTIONAL);

		bind_property ("subview-title", header_bar,
		               "subview-title", BindingFlags.BIDIRECTIONAL);

		konami_code = new KonamiCode (window);
		konami_code.code_performed.connect (on_konami_code_performed);
	}

	public CollectionView (Gtk.Window window, GameModel game_model) {
		Object (window: window, game_model: game_model);
	}

	public void show_error (string error_message) {
		error_info_bar.show_error (error_message);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (window.get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((window.get_direction () == Gtk.TextDirection.LTR) && keyval == Gdk.Key.Left) ||
		     ((window.get_direction () == Gtk.TextDirection.RTL) && keyval == Gdk.Key.Right)) &&
		     header_bar.back ())
			return true;

		if ((keyval == Gdk.Key.f || keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK &&
		    !is_collection_empty) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		if (is_collection_empty)
			return false;

		return search_bar.handle_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		if (is_collection_empty)
			return false;

		switch (button) {
		case EventCode.BTN_TL:
			var views = viewstack.get_children ();
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.prev != null)
				viewstack.visible_child = current_view.prev.data;

			return true;
		case EventCode.BTN_TR:
			var views = viewstack.get_children ();
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.next != null)
				viewstack.visible_child = current_view.next.data;

			return true;
		default:
			if (viewstack.visible_child == platform_view)
				return platform_view.gamepad_button_press_event (event);
			else
				return collection_view.gamepad_button_press_event (event);
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_button_release_event (event);
		else
			return collection_view.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_absolute_axis_event (event);
		else
			return collection_view.gamepad_absolute_axis_event (event);
	}

	private void on_konami_code_performed () {
		if (!is_view_active)
			return;

		try {
			Gtk.show_uri_on_window (window, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void run_search (string query) {
		search_mode = true;
		search_bar.run_search (query);
	}

	[GtkCallback]
	private void on_loading_notification_closed () {
		loading_notification = false;
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (viewstack.visible_child == collection_view)
			collection_view.reset_scroll_position ();
		else
			platform_view.reset ();
	}

	[GtkCallback]
	private void on_search_text_notify () {
		filtering_text = search_bar.text;
		if (found_games ())
			empty_stack.visible_child = viewstack;
		else
			empty_stack.visible_child = empty_search;

		// Changing the filtering_text for the PlatformView might
		// cause the currently selected sidebar row to become empty and therefore
		// hidden. In this case the first visible row will become selected and
		// this causes the search bar to lose focus so we have to regrab it here
		search_bar.focus_entry ();
	}

	private bool found_games () {
		for (int i = 0; i < game_model.get_n_items (); i++) {
			var game = game_model.get_item (i) as Game;

			if (game.matches_search_terms (filtering_terms))
				return true;
		}

		return false;
	}

	[GtkCallback]
	private void update_bottom_bar () {
		view_switcher_bar.reveal = is_showing_bottom_bar && (!is_folded || !is_subview_open);
	}
}
