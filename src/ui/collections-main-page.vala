// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collections-main-page.ui")]
private class Games.CollectionsMainPage : Gtk.Bin {
	public signal void collection_activated (Collection collection);
	public signal void gamepad_accepted ();

	private Binding window_active_binding;
	private bool _is_active;
	public bool is_active {
		get { return _is_active; }
		set {
			if (_is_active == value)
				return;

			_is_active = value;

			if (!_is_active)
				gamepad_browse.cancel_cursor_movement ();
		}
	}

	private CollectionModel _collection_model;
	public CollectionModel collection_model {
		get { return _collection_model; }
		set {
			_collection_model = value;
			flow_box.bind_model (collection_model, add_collection);
			flow_box.set_filter_func (collection_filter_func);
		}
	}

	[GtkChild]
	private Gtk.FlowBox flow_box;
	[GtkChild]
	private GamepadBrowse gamepad_browse;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;

	static construct {
		set_css_name ("gamescollectionsmainpage");
	}

	construct {
		flow_box.max_children_per_line = uint.MAX;
	}

	public bool has_collection_selected () {
		foreach (var child in flow_box.get_selected_children ())
			if (child.get_mapped ())
				return true;

		return false;
	}

	public bool select_default_collection (Gtk.DirectionType direction) {
		Gtk.FlowBoxChild? child;
		for (int i = 0; (child = flow_box.get_child_at_index (i)) != null; i++) {
			if (child.get_mapped ()) {
				flow_box.select_child (child);
				// This is needed to start moving the cursor with the gamepad only.
				child.focus (direction);

				return true;
			}
		}

		return false;
	}

	private Gtk.Widget add_collection (Object item) {
		return new CollectionIconView (item as Collection);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		return gamepad_browse.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		return gamepad_browse.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		return gamepad_browse.gamepad_absolute_axis_event (event);
	}

	public void reset_scroll_position () {
		var adjustment = scrolled_window.get_vadjustment ();
		adjustment.value = 0;
	}

	public void invalidate_filter () {
		flow_box.invalidate_filter ();
	}

	private bool collection_filter_func (Gtk.FlowBoxChild child) {
		var collection_icon_view = child as CollectionIconView;
		if (collection_icon_view == null)
			return false;

		return !collection_icon_view.collection.is_empty;
	}

	[GtkCallback]
	public void on_map () {
		window_active_binding = null;
		is_active = false;

		var window = get_ancestor (typeof (Gtk.Window));
		if (window == null)
			return;

		window_active_binding = window.bind_property ("is-active", this, "is-active", BindingFlags.SYNC_CREATE);
	}

	[GtkCallback]
	public void on_unmap () {
		window_active_binding = null;
		is_active = false;
	}

	[GtkCallback]
	private bool on_gamepad_browse (Gtk.DirectionType direction) {
		if (!has_collection_selected ())
			// This is needed to start moving the cursor with the gamepad only.
			return select_default_collection (direction);

		switch (direction) {
		case Gtk.DirectionType.UP:
			return flow_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, -1);
		case Gtk.DirectionType.DOWN:
			return flow_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, 1);
		case Gtk.DirectionType.LEFT:
			return flow_box.move_cursor (Gtk.MovementStep.VISUAL_POSITIONS, -1);
		case Gtk.DirectionType.RIGHT:
			return flow_box.move_cursor (Gtk.MovementStep.VISUAL_POSITIONS, 1);
		default:
			return false;
		}
	}

	[GtkCallback]
	private bool on_gamepad_accept () {
		flow_box.activate_cursor_child ();
		gamepad_accepted ();

		return true;
	}

	[GtkCallback]
	private void on_child_activated (Gtk.FlowBoxChild child) {
		var collection_icon_view = child as CollectionIconView;
		if (collection_icon_view != null)
			collection_activated (collection_icon_view.collection);
	}

	[GtkCallback]
	private void on_size_allocate (Gtk.Allocation allocation) {
		// If the window's width is less than half the width of a 1920×1080
		// screen, display the game thumbnails at half the size to see more of
		// them rather than a few huge thumbnails, making Games more usable on
		// small screens.
		if (allocation.width < 960)
			get_style_context ().remove_class ("large");
		else
			get_style_context ().add_class ("large");
	}
}
