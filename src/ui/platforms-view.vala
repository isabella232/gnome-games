// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/platforms-view.ui")]
private class Games.PlatformsView : Gtk.Box {
	public signal void game_activated (Game game);

	private ulong model_items_changed_id;
	private GenericSet<Platform> platforms;
	private Platform selected_platform;

	private string[] filtering_terms;
	public string filtering_text {
		set {
			collection_view.filtering_text = value;

			if (value != null)
				filtering_terms = value.split (" ");

			hide_empty_sidebar_items ();
		}
	}

	private ListModel _model;
	public ListModel model {
		get { return _model; }
		set {
			if (model_items_changed_id != 0) {
				_model.disconnect (model_items_changed_id);
				model_items_changed_id = 0;
			}

			_model = value;
			collection_view.model = _model;

			if (model != null)
				model_items_changed_id = model.items_changed.connect (on_model_changed);
		}
	}

	private Binding window_active_binding;
	private bool _is_active;
	public bool is_active {
		get {
			return _is_active;
		}
		set {
			if (_is_active == value)
				return;

			_is_active = value;

			if (!_is_active)
				gamepad_browse.cancel_cursor_movement ();
		}
	}

	[GtkChild]
	private CollectionIconView collection_view;

	[GtkChild]
	private Gtk.ListBox list_box;

	[GtkChild]
	private GamepadBrowse gamepad_browse;

	construct {
		platforms = new GenericSet<Platform> (Platform.hash, Platform.equal);

		list_box.set_sort_func (sort_rows);

		collection_view.game_activated.connect ((game) => {
			game_activated (game);
		});

		collection_view.set_game_filter (filter_game);
	}

	private int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = row1 as PlatformListItem;
		var item2 = row2 as PlatformListItem;

		return PlatformListItem.compare (item1, item2);
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

			list_box.select_row (first_row);
			// This is needed to start moving the cursor with the gamepad only.
			first_row.focus (direction);

			return true;
		}

		switch (direction) {
		case Gtk.DirectionType.UP:
			list_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, -1);

			return true;
		case Gtk.DirectionType.DOWN:
			list_box.move_cursor (Gtk.MovementStep.DISPLAY_LINES, 1);

			return true;
		case Gtk.DirectionType.RIGHT:
			list_box.activate_cursor_row ();

			return true;
		default:
			return false;
		}
	}

	[GtkCallback]
	private bool on_gamepad_accept () {
		list_box.activate_cursor_row ();

		return true;
	}

	[GtkCallback]
	private bool on_gamepad_cancel () {
		collection_view.unselect_game ();

		return true;
	}

	[GtkCallback]
	private void on_list_box_row_selected (Gtk.ListBoxRow? row_item) {
		if (row_item == null)
			return;

		var row = row_item as PlatformListItem;
		list_box.select_row (row);
		row.focus (Gtk.DirectionType.LEFT);
		selected_platform = row.platform;

		collection_view.invalidate_flow_box_filter ();
		collection_view.reset_scroll_position ();
		collection_view.unselect_game ();
	}

	[GtkCallback]
	private void on_list_box_row_activated (Gtk.ListBoxRow row_item) {
		collection_view.select_default_game (Gtk.DirectionType.RIGHT);
	}

	private void on_model_changed (uint position, uint removed, uint added) {
		// FIXME: currently games are never removed, update this function if
		// necessary.
		assert (removed == 0);

		for (uint i = position; i < position + added; i++) {
			var game = model.get_item (i) as Game;
			var platform = game.get_platform ();

			if (!platforms.contains (platform)) {
				platforms.add (platform);

				var platform_list_item = new PlatformListItem (platform);
				list_box.add (platform_list_item);
			}
		}
	}

	public void select_default_row () {
		foreach (var child in list_box.get_children ()) {
			var row = child as Gtk.ListBoxRow;

			if (row.visible) {
				on_list_box_row_selected (row);
				break;
			}
		}
	}

	private void hide_empty_sidebar_items () {
		// Create an array of all the games which fit the search text entered
		// in the top search bar
		Game[] visible_games = {};

		for (int i = 0; i < model.get_n_items (); i++) {
			var game = model.get_item (i) as Game;

			if (game.matches_search_terms (filtering_terms))
				visible_games += game;
		}

		foreach (var row in list_box.get_children ()) {
			var platform_item = row as PlatformListItem;
			var platform = platform_item.platform;
			// Assume row doesn't have any games to show
			var is_row_visible = false;

			foreach (var game in visible_games) {
				var game_platform = game.get_platform ().get_name ();

				if (game_platform == platform.get_name ()) {
					is_row_visible = true;
					break;
				}
			}

			row.visible = is_row_visible;
		}

		select_default_row ();
	}
}
