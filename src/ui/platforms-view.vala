// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/platforms-view.ui")]
private class Games.PlatformsView : Gtk.Bin {
	public signal void game_activated (Game game);

	[GtkChild]
	private Hdy.Leaflet leaflet;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private GamesPage games_page;
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
			games_page.game_model = value;

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
		games_page.set_game_filter (filter_game);
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
			if (game.platform == item.platform)
				return true;

		return false;
	}

	private bool filter_game (Game game) {
		if (selected_platform != null &&
		    selected_platform.get_name () != game.platform.get_name ())
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
		games_page.set_filter (filtering_terms);

		list_box.invalidate_filter ();
		select_first_visible_row ();
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (games_page.has_game_selected ())
			if (games_page.gamepad_button_press_event (event))
				return true;

		return gamepad_browse.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (games_page.has_game_selected ())
			if (games_page.gamepad_button_release_event (event))
				return true;

		return gamepad_browse.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (games_page.has_game_selected ())
			if (games_page.gamepad_absolute_axis_event (event))
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
			leaflet.navigate (Hdy.NavigationDirection.FORWARD);
			games_page.select_default_game (Gtk.DirectionType.RIGHT);

			return true;
		default:
			return false;
		}
	}

	[GtkCallback]
	private bool on_gamepad_accept () {
		leaflet.navigate (Hdy.NavigationDirection.FORWARD);
		games_page.select_default_game (Gtk.DirectionType.RIGHT);

		return true;
	}

	[GtkCallback]
	private bool on_gamepad_cancel () {
		games_page.unselect_game ();
		leaflet.navigate (Hdy.NavigationDirection.BACK);

		return true;
	}

	[GtkCallback]
	private void on_list_box_row_activated (Gtk.ListBoxRow row_item) {
		select_platform_for_row (row_item);

		leaflet.navigate (Hdy.NavigationDirection.FORWARD);
	}

	private void select_platform_for_row (Gtk.ListBoxRow row_item) {
		var row = row_item as PlatformListItem;
		selected_platform = row.platform;
		subview_title = selected_platform.get_name ();

		games_page.invalidate_filter ();
		games_page.reset_scroll_position ();
	}

	public void reset () {
		select_first_visible_row ();
		leaflet.navigate (Hdy.NavigationDirection.BACK);
	}

	private void select_first_visible_row () {
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
	}

	[GtkCallback]
	public void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		is_subview_open = (leaflet.visible_child == games_page);
	}

	public Hdy.Leaflet get_leaflet () {
		return leaflet;
	}
}
