// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collections-main-page.ui")]
private class Games.CollectionsMainPage : Gtk.Bin {
	public signal void collection_activated (Collection collection);
	public signal void selected_items_changed ();
	public signal void gamepad_accepted ();

	[GtkChild]
	private Gtk.FlowBox flow_box;
	[GtkChild]
	private GamepadBrowse gamepad_browse;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;

	private string[] filtering_terms;
	private Binding window_active_binding;
	private GenericSet<CollectionIconView> selected_collections;

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

	public bool is_selection_mode { get; set; }
	public bool is_search_mode { get; set; }
	public bool is_search_empty { get; set; }

	static construct {
		set_css_name ("gamescollectionsmainpage");
	}

	construct {
		flow_box.max_children_per_line = uint.MAX;

		selected_collections = new GenericSet<CollectionIconView> (CollectionIconView.hash, CollectionIconView.equal);
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
		var collection_icon_view = new CollectionIconView (item as Collection);
		if (item is UserCollection) {
			bind_property ("is-selection-mode", collection_icon_view, "is-selection-mode", BindingFlags.DEFAULT);
			collection_icon_view.notify["checked"].connect (() => {
				assert (collection_icon_view.collection is UserCollection);

				if (collection_icon_view.checked)
					selected_collections.add (collection_icon_view);
				else
					selected_collections.remove (collection_icon_view);

				selected_items_changed ();
			});
		}
		else
			bind_property ("is-selection-mode", collection_icon_view, "sensitive", BindingFlags.INVERT_BOOLEAN);

		return collection_icon_view;
	}

	public void select_none () {
		foreach (var icon_view in selected_collections.get_values ())
			icon_view.checked = false;

		selected_collections.remove_all ();
		selected_items_changed ();
	}

	public void select_all () {
		foreach (var child in flow_box.get_children ()) {
			var collection_icon_view = child as CollectionIconView;
			if (is_search_mode)
				collection_icon_view.checked = filtering_terms == null ||
				                               filter_collection (collection_icon_view.collection);
			else
				collection_icon_view.checked = collection_icon_view.collection is UserCollection;
		}

		selected_items_changed ();
	}

	public UserCollection[] get_selected_collections () {
		UserCollection[] collections = {};
		foreach (var collection_icon_view in selected_collections.get_values ())
			collections += collection_icon_view.collection as UserCollection;

		return collections;
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

	public void invalidate_sort () {
		collection_model.invalidate_sort ();
	}

	public void set_filter (string[] filtering_terms) {
		this.filtering_terms = filtering_terms;
		invalidate_filter ();
		update_search_empty ();
	}

	private void update_search_empty () {
		if (!is_search_mode || filtering_terms == null) {
			is_search_empty = false;
			return;
		}

		for (var i = 0; i < collection_model.get_n_items (); i++) {
			var collection = collection_model.get_item (i) as Collection;
			var type = collection.get_collection_type ();

			if (type == CollectionType.PLACEHOLDER ||
			   (type == CollectionType.AUTO && collection.is_empty))
				continue;

			if (collection.matches_search_terms (filtering_terms)) {
				is_search_empty = false;
				return;
			}
		}

		is_search_empty = true;
	}

	private bool filter_collection (Collection collection) {
		return collection.matches_search_terms (filtering_terms);
	}

	private bool collection_filter_func (Gtk.FlowBoxChild child) {
		var collection_icon_view = child as CollectionIconView;
		if (collection_icon_view == null)
			return false;

		var collection = collection_icon_view.collection;
		var type = collection.get_collection_type ();

		if (is_search_mode && filtering_terms.length != 0) {
			switch (type) {
			case CollectionType.AUTO:
				return !collection.is_empty && filter_collection (collection);

			case CollectionType.USER:
				return filter_collection (collection);

			case CollectionType.PLACEHOLDER:
				return false;
			}
		}

		return !collection_icon_view.collection.is_empty || type != CollectionType.AUTO;
	}

	[GtkCallback]
	private void on_search_mode_changed () {
		update_search_empty ();
		invalidate_filter ();
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

		if (is_selection_mode) {
			collection_icon_view.checked = !collection_icon_view.checked;
			return;
		}

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
