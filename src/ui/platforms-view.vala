// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/platforms-view.ui")]
private class Games.PlatformsView : Gtk.Bin {
	public signal void game_activated (Game game);

	[GtkChild]
	private Hdy.Leaflet leaflet;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private CollectionIconView collection_view;
	[GtkChild]
	private GamepadBrowse gamepad_browse;

	private Platform selected_platform;
	private bool has_used_gamepad;

	private string[] filtering_terms;

	private GameModel _game_model;
	public GameModel game_model {
		get { return _game_model; }
		set {
			_game_model = value;
			collection_view.game_model = value;

			var platform_model = new PlatformModel (value);
			list_box.bind_model (platform_model, add_platform);
		}
	}

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

	public bool is_folded { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }

	construct {
		collection_view.set_game_filter (filter_game);
		list_box.set_filter_func (filter_list);
	}

	private bool filter_list (Gtk.ListBoxRow? row) {
		var item = row as PlatformListItem;
		if (item == null)
			return false;

		if (item.platform == null)
			return false;

		Game[] visible_games = {};
		for (int i = 0; i < game_model.get_n_items (); i++) {
			var game = game_model.get_item (i) as Game;

			if (game.matches_search_terms (filtering_terms))
				visible_games += game;
		}

		foreach (var game in visible_games)
			if (game.get_platform () == item.platform)
				return true;

		return false;
	}

	private bool filter_game (Game game) {
		if (selected_platform != null &&
		    selected_platform.get_name () != game.get_platform ().get_name ())
			return false;

		return true;
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

	public void set_filter (string[] filtering_terms) {
		this.filtering_terms = filtering_terms;
		collection_view.set_filter (filtering_terms);

		list_box.invalidate_filter ();
		select_first_visible_row ();
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (collection_view.has_game_selected ())
			if (collection_view.gamepad_button_press_event (event))
				return true;

		return gamepad_browse.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (collection_view.has_game_selected ())
			if (collection_view.gamepad_button_release_event (event))
				return true;

		return gamepad_browse.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (collection_view.has_game_selected ())
			if (collection_view.gamepad_absolute_axis_event (event))
				return true;

		return gamepad_browse.gamepad_absolute_axis_event (event);
	}

	[GtkCallback]
	private bool on_gamepad_browse (Gtk.DirectionType direction) {
		if (list_box.get_selected_rows ().length () == 0) {
			var first_row = list_box.get_row_at_index (0);
			if (first_row == null)
				return false;

			has_used_gamepad = true;
			update_selection_mode ();

			// This is needed to start moving the cursor with the gamepad only.
			first_row.focus (direction);

			return true;
		}

		switch (direction) {
		case Gtk.DirectionType.UP:
			list_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, -1);
			select_platform_for_row (list_box.get_selected_row ());

			return true;
		case Gtk.DirectionType.DOWN:
			list_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, 1);
			select_platform_for_row (list_box.get_selected_row ());

			return true;
		case Gtk.DirectionType.RIGHT:
			is_subview_open = true;
			collection_view.select_default_game (Gtk.DirectionType.RIGHT);

			return true;
		default:
			return false;
		}
	}

	[GtkCallback]
	private bool on_gamepad_accept () {
		is_subview_open = true;
		collection_view.select_default_game (Gtk.DirectionType.RIGHT);

		return true;
	}

	[GtkCallback]
	private bool on_gamepad_cancel () {
		collection_view.unselect_game ();
		is_subview_open = false;

		return true;
	}

	[GtkCallback]
	private void on_list_box_row_activated (Gtk.ListBoxRow row_item) {
		select_platform_for_row (row_item);

		is_subview_open = true;
	}

	private void select_platform_for_row (Gtk.ListBoxRow row_item) {
		var row = row_item as PlatformListItem;
		selected_platform = row.platform;
		subview_title = selected_platform.get_name ();

		collection_view.invalidate_filter ();
		collection_view.reset_scroll_position ();
	}

	public void select_first_visible_row () {
		foreach (var child in list_box.get_children ()) {
			var row = child as Gtk.ListBoxRow;

			if (row.get_child_visible ()) {
				list_box.select_row (row);
				row.focus (Gtk.DirectionType.LEFT);
				select_platform_for_row (row);
				break;
			}
		}
	}

	private void select_current_row () {
		if (is_folded && !has_used_gamepad)
			return;

		foreach (var child in list_box.get_children ()) {
			var platform_item = child as PlatformListItem;

			if (Platform.equal (platform_item.platform, selected_platform)) {
				list_box.select_row (platform_item);
				break;
			}
		}
	}

	private Gtk.Widget add_platform (Object object) {
		var platform = object as Platform;

		var item = new PlatformListItem (platform);
		item.show ();

		return item;
	}

	[GtkCallback]
	private void update_selection_mode () {
		if (!is_folded || has_used_gamepad)
			list_box.selection_mode = Gtk.SelectionMode.SINGLE;
		else
			list_box.selection_mode = Gtk.SelectionMode.NONE;
		select_current_row ();
	}

	[GtkCallback]
	private void on_leaflet_folded_changed () {
		is_folded = leaflet.folded;
		if (leaflet.folded)
			leaflet.get_style_context ().add_class ("folded");
		else
			leaflet.get_style_context ().remove_class ("folded");
	}

	[GtkCallback]
	public void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void update_subview () {
		if (is_subview_open)
			leaflet.visible_child = collection_view;
		else
			leaflet.visible_child = scrolled_window;
	}
}
