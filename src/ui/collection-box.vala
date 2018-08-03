// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-box.ui")]
private class Games.CollectionBox : Gtk.Box {
	public signal void game_activated (Game game);

	public ListModel collection { construct set; get; }
	public bool search_mode { set; get; }
	public bool loading_notification { set; get; }

	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private Gtk.Revealer loading_notification_revealer;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private DevelopersView developer_view;
	[GtkChild]
	private PlatformsView platform_view;
	[GtkChild (name = "viewstack")]
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
	}

	private Binding collection_binding;
	private Binding developer_collection_binding;
	private Binding platform_collection_binding;
	private Binding search_binding;
	private Binding loading_notification_binding;

	public CollectionBox (ListStore collection) {
		Object (collection: collection);
	}

	construct {
		collection_binding = bind_property ("collection", collection_view, "model",
		                                    BindingFlags.BIDIRECTIONAL);

		developer_collection_binding = bind_property ("collection", developer_view,
		                                              "model", BindingFlags.BIDIRECTIONAL);

		platform_collection_binding = bind_property ("collection", platform_view,
		                                             "model", BindingFlags.BIDIRECTIONAL);

		search_binding = bind_property ("search-mode", search_bar, "search-mode-enabled",
		                                BindingFlags.BIDIRECTIONAL);
		loading_notification_binding = bind_property ("loading-notification", loading_notification_revealer, "reveal-child",
		                                              BindingFlags.DEFAULT);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!visible)
			return false;

		uint16 button;
		if (!event.get_button (out button))
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
			return collection_view.gamepad_button_press_event (event);
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return collection_view.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return collection_view.gamepad_absolute_axis_event (event);
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
		if (viewstack.visible_child == platform_view) {
			platform_view.select_default_row ();
		}
		else if (viewstack.visible_child == developer_view) {
			developer_view.select_default_row ();
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

	public bool search_bar_handle_event (Gdk.Event event) {
		return search_bar.handle_event (event);
	}
}
