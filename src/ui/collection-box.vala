// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-box.ui")]
private class Games.CollectionBox : Gtk.Box {
	public signal void game_activated (Game game);

	public ListModel collection { get; construct; }
	public bool search_mode { get; set; }
	public bool loading_notification { get; set; }

	[GtkChild]
	private ErrorInfoBar error_info_bar;
	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private EmptyCollection empty_collection;
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

	public Gtk.Stack viewstack {
		get { return _viewstack; }
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

	public bool is_folded { get; set; }
	public bool is_showing_bottom_bar { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }

	construct {
		var icon_name = Config.APPLICATION_ID + "-symbolic";
		viewstack.child_set (collection_view, "icon-name", icon_name);

		collection_view.model = collection;
		platform_view.model = collection;
	}

	public CollectionBox (ListModel collection) {
		Object (collection: collection);
	}

	public void show_error (string error_message) {
		error_info_bar.show_error (error_message);
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
		loading_notification = false;
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

		is_subview_open = false;
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
		if (is_collection_empty)
			return false;

		return search_bar.handle_event (event);
	}

	[GtkCallback]
	private void update_bottom_bar () {
		view_switcher_bar.reveal = is_showing_bottom_bar && (!is_folded || !is_subview_open);
	}
}
