// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-box.ui")]
private class Games.CollectionBox : Gtk.Box {
	public signal void game_activated (Game game);

	public ListModel collection { get; construct set; }
	public bool search_mode { get; set; }
	public bool loading_notification { get; set; }

	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private Gtk.Revealer loading_notification_revealer;
	[GtkChild]
	private Gtk.Box sidebar_box;
	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private GamesView games_view;
	[GtkChild]
	private DevelopersView developer_view;
	[GtkChild]
	private PlatformsView platform_view;
	[GtkChild (name = "viewstack")]
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
	}
	[GtkChild]
	private Gtk.Stack empty_stack;

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (_is_collection_empty)
				empty_stack.visible_child = empty_collection;
			else
				empty_stack.visible_child = sidebar_box;
		}
	}

	private Binding collection_binding;
	private Binding search_binding;
	private Binding loading_notification_binding;

	public CollectionBox (ListStore collection) {
		Object (collection: collection);
	}

	construct {
		collection_binding = bind_property ("collection", collection_view, "model",
		                                    BindingFlags.BIDIRECTIONAL);
		search_binding = bind_property ("search-mode", search_bar, "search-mode-enabled",
		                                BindingFlags.BIDIRECTIONAL);
		loading_notification_binding = bind_property ("loading-notification", loading_notification_revealer, "reveal-child",
		                                              BindingFlags.DEFAULT);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
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
			unowned List<Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.prev != null)
				viewstack.visible_child = current_view.prev.data;

			return true;
		case EventCode.BTN_TR:
			var views = viewstack.get_children ();
			unowned List<Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.next != null)
				viewstack.visible_child = current_view.next.data;

			return true;
		default:
			var view = viewstack.visible_child as SidebarView;

			return view.gamepad_button_press_event (event);
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		var view = viewstack.visible_child as SidebarView;

		return view.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		var view = viewstack.visible_child as SidebarView;

		return view.gamepad_absolute_axis_event (event);
	}

	[GtkCallback]
	private void on_loading_notification_closed () {
		loading_notification_revealer.set_reveal_child (false);
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		collection_view.filtering_developer = null;
		collection_view.filtering_platform = null;

		var view = viewstack.visible_child as SidebarView;

		viewstack.visible = !view.is_collapsed;

		view.select_default_row ();
	}

	[GtkCallback]
	private void on_search_text_notify () {
		collection_view.filtering_text = search_bar.text;
	}

	public bool search_bar_handle_event (Gdk.Event event) {
		return search_bar.handle_event (event);
	}
}
