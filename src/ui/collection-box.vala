// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-box.ui")]
private class Games.CollectionBox : Gtk.Box {
	public signal void game_activated (Game game);

	public ListModel collection { get; construct set; }
	public bool search_mode { get; set; }
	public bool loading_notification { get; set; }

	[GtkChild]
	private ErrorInfoBar error_info_bar;
	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private Gtk.Revealer loading_notification_revealer;
	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private PlatformsView platform_view;
	[GtkChild (name = "viewstack")]
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (_is_collection_empty)
				viewstack.visible_child = empty_collection;
			else
				viewstack.visible_child = collection_view;
		}
	}

	private Binding collection_binding;
	private Binding platform_collection_binding;
	private Binding search_binding;
	private Binding loading_notification_binding;

	public CollectionBox (ListModel collection) {
		Object (collection: collection);
	}

	construct {
		collection_binding = bind_property ("collection", collection_view, "model",
		                                    BindingFlags.BIDIRECTIONAL);

		platform_collection_binding = bind_property ("collection", platform_view,
		                                             "model", BindingFlags.BIDIRECTIONAL);

		search_binding = bind_property ("search-mode", search_bar, "search-mode-enabled",
		                                BindingFlags.BIDIRECTIONAL);
		loading_notification_binding = bind_property ("loading-notification",
		                                              loading_notification_revealer,
		                                              "reveal-child", BindingFlags.DEFAULT);

		var icon_name = Config.APPLICATION_ID + "-symbolic";
		viewstack.child_set (collection_view, "icon-name", icon_name);
	}

	public void show_error (string error_message) {
		error_info_bar.message = error_message;
		error_info_bar.revealed = true;
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
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.prev != null && current_view.prev.data != empty_collection)
				viewstack.visible_child = current_view.prev.data;

			return true;
		case EventCode.BTN_TR:
			var views = viewstack.get_children ();
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.next != null && current_view.next.data != empty_collection)
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
		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_button_release_event (event);
		else
			return collection_view.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platform_view)
			return platform_view.gamepad_absolute_axis_event (event);
		else
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
		if (viewstack.visible_child == platform_view)
			platform_view.filtering_text = search_bar.text;
		else {
			collection_view.filtering_text = search_bar.text;
			collection_view.reset_scroll_position ();
		}
	}

	[GtkCallback]
	private void on_search_text_notify () {
		if (viewstack.visible_child == platform_view)
			platform_view.filtering_text = search_bar.text;
		else
			collection_view.filtering_text = search_bar.text;

		// Changing the filtering_text for the PlatformView might
		// cause the currently selected sidebar row to become empty and therefore
		// hidden. In this case the first visible row will become selected and
		// this causes the search bar to lose focus so we have to regrab it here
		search_bar.focus_entry ();
	}

	public bool search_bar_handle_event (Gdk.Event event) {
		return search_bar.handle_event (event);
	}
}
