// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-view.ui")]
private class Games.CollectionView: Gtk.Box, ApplicationView {
	public signal void game_activated (Game game);

	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private Gtk.Revealer loading_notification_revealer;
	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private DevelopersView developer_view;
	[GtkChild]
	private PlatformsView platform_view;
	[GtkChild]
	private Gtk.Stack viewstack;
	[GtkChild]
	private Gtk.Stack title_stack;
	[GtkChild]
	private Gtk.Label empty_title;
	[GtkChild]
	private Gtk.StackSwitcher view_switcher;
	[GtkChild]
	private Gtk.ToggleButton search;
	[GtkChild]
	private Gtk.HeaderBar header_bar;

	public Gtk.Widget titlebar {
		get { return header_bar; }
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
		}
	}

	public ApplicationWindow window { get; construct set; }

	private ListModel _collection;
	public ListModel collection {
		get { return _collection; }
		construct set {
			_collection = value;

			collection.items_changed.connect (() => {
				is_collection_empty = collection.get_n_items () == 0;
			});
			is_collection_empty = collection.get_n_items () == 0;
		}
	}

	public bool loading_notification { get; set; }
	public bool search_mode { get; set; }

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (_is_collection_empty) {
				viewstack.visible_child = empty_collection;
				title_stack.visible_child = empty_title;
			}
			else {
				viewstack.visible_child = collection_view;
				title_stack.visible_child = view_switcher;
			}
			search.sensitive = !_is_collection_empty;
		}
	}

	private Binding loading_notification_binding;
	private Binding box_search_binding;
	private Binding header_bar_search_binding;

	private Binding collection_binding;
	private Binding developer_collection_binding;
	private Binding platform_collection_binding;

	construct {
		view_switcher.stack = viewstack;
		is_collection_empty = true;

		loading_notification_binding = bind_property ("loading-notification",
		                                              loading_notification_revealer,
		                                              "reveal-child",
		                                              BindingFlags.DEFAULT);

		box_search_binding = bind_property ("search-mode", search_bar,
		                                    "search-mode-enabled",
		                                    BindingFlags.BIDIRECTIONAL);
		header_bar_search_binding = bind_property ("search-mode", search, "active",
		                                           BindingFlags.BIDIRECTIONAL);

		collection_binding = bind_property ("collection", collection_view, "model",
		                                    BindingFlags.BIDIRECTIONAL);
		developer_collection_binding = bind_property ("collection", developer_view,
		                                              "model", BindingFlags.BIDIRECTIONAL);
		platform_collection_binding = bind_property ("collection", platform_view,
		                                             "model", BindingFlags.BIDIRECTIONAL);
	}

	public CollectionView (ListModel collection) {
		this.collection = collection;
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.f || event.keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		return search_bar.handle_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!window.is_active || !get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		if (is_collection_empty)
			return false;

		switch (button) {
		case EventCode.BTN_TL:
			var views = viewstack.get_children ();
			unowned List<Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.prev != null && current_view.prev.data != empty_collection)
				viewstack.visible_child = current_view.prev.data;

			return true;
		case EventCode.BTN_TR:
			var views = viewstack.get_children ();
			unowned List<Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.next != null && current_view.next.data != empty_collection)
				viewstack.visible_child = current_view.next.data;

			return true;
		default:
			if (viewstack.visible_child == platform_view)
				return platform_view.gamepad_button_press_event (event);
			else if (viewstack.visible_child == developer_view)
				return developer_view.gamepad_button_press_event (event);
			else
				return collection_view.gamepad_button_press_event (event);
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!window.is_active || !get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_button_release_event (event);
		else if (viewstack.visible_child == developer_view)
			return developer_view.gamepad_button_release_event (event);
		else
			return collection_view.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!window.is_active || !get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_absolute_axis_event (event);
		else if (viewstack.visible_child == developer_view)
			return developer_view.gamepad_absolute_axis_event (event);
		else
			return collection_view.gamepad_absolute_axis_event (event);
	}

	[GtkCallback]
	private void on_loading_notification_closed () {
		loading_notification_revealer.set_reveal_child (false);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (viewstack.visible_child == platform_view) {
			platform_view.select_default_row ();
		}
		else if (viewstack.visible_child == developer_view) {
			developer_view.select_default_row ();
		}
		else {
			collection_view.reset_scroll_position ();
		}
	}

	[GtkCallback]
	private void on_search_text_notify () {
		if (viewstack.visible_child == platform_view) {
			platform_view.filtering_text = search_bar.text;
		}
		else if (viewstack.visible_child == developer_view) {
			developer_view.filtering_text = search_bar.text;
		}
		else
			collection_view.filtering_text = search_bar.text;
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}
}
