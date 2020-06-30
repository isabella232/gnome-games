// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/games-page.ui")]
private class Games.GamesPage : Gtk.Bin {
	public signal void game_activated (Game game);
	public signal void selected_items_changed ();
	public signal bool gamepad_cancel_clicked ();

	private string[] filtering_terms;
	public bool is_selection_mode { get; set; }

	public delegate bool GameFilter (Game game);
	private unowned GameFilter? game_filter;
	public void set_game_filter (GameFilter? game_filter) {
		this.game_filter = game_filter;
	}

	private GameModel _game_model;
	public GameModel game_model {
		get { return _game_model; }
		set {
			_game_model = value;
			flow_box.bind_model (game_model, add_game);
		}
	}

	private bool _hide_stars;
	public bool hide_stars {
		get { return _hide_stars; }
		set {
			_hide_stars = value;

			if (hide_stars)
				get_style_context ().add_class ("hide-stars");
			else
				get_style_context ().remove_class ("hide-stars");
		}
	}

	private GenericSet<GameIconView> selected_games;
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

	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;
	[GtkChild]
	private Gtk.FlowBox flow_box;

	[GtkChild]
	private GamepadBrowse gamepad_browse;

	static construct {
		set_css_name ("gamesgamespage");
	}

	construct {
		flow_box.max_children_per_line = uint.MAX;
		flow_box.set_filter_func (filter_box);

		selected_games = new GenericSet<GameIconView> (GameIconView.hash, GameIconView.equal);
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

	public void set_filter (string[] filtering_terms) {
		this.filtering_terms = filtering_terms;
		flow_box.invalidate_filter ();
	}

	public void reset_scroll_position () {
		var adjustment = scrolled_window.get_vadjustment ();
		adjustment.value = 0;
	}

	public bool has_game_selected () {
		foreach (var child in flow_box.get_selected_children ())
			if (child.get_mapped ())
				return true;

		return false;
	}

	public bool select_default_game (Gtk.DirectionType direction) {
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

	public void unselect_game () {
		flow_box.unselect_all ();
	}

	public void select_none () {
		foreach (var game_icon_view in selected_games.get_values ())
			game_icon_view.checked = false;

		selected_games.remove_all ();
	}

	public void select_all () {
		foreach (var child in flow_box.get_children ()) {
			var game_icon_view = child as GameIconView;
			if (game_filter == null)
				game_icon_view.checked = filtering_terms == null || filter_game (game_icon_view.game);
			else if (filter_game (game_icon_view.game))
				game_icon_view.checked = true;
		}
	}

	public Game[] get_selected_games () {
		Game[] games = {};
		foreach (var game_icon_view in selected_games.get_values ())
			games += game_icon_view.game;

		return games;
	}

	[GtkCallback]
	private bool on_gamepad_browse (Gtk.DirectionType direction) {
		if (!has_game_selected ())
			// This is needed to start moving the cursor with the gamepad only.
			return select_default_game (direction);

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

		return true;
	}

	[GtkCallback]
	private bool on_gamepad_cancel () {
		return gamepad_cancel_clicked ();
	}

	[GtkCallback]
	private void on_child_activated (Gtk.FlowBoxChild child) {
		var game_view = child as GameIconView;

		if (is_selection_mode) {
			game_view.checked = !game_view.checked;
			return;
		}

		game_activated (game_view.game);
	}

	private Gtk.Widget add_game (Object item) {
		var game_icon = new GameIconView (item as Game);
		bind_property ("is-selection-mode", game_icon, "is-selection-mode", BindingFlags.DEFAULT);

		game_icon.notify["checked"].connect (() => {
			if (game_icon.checked)
				selected_games.add (game_icon);
			else
				selected_games.remove (game_icon);

			selected_items_changed ();
		});

		return game_icon;
	}

	public void invalidate_filter () {
		flow_box.invalidate_filter ();
	}

	private bool filter_box (Gtk.FlowBoxChild child) {
		var game_view = child as GameIconView;
		if (game_view == null)
			return false;

		if (game_view.game == null)
			return false;

		return filter_game (game_view.game);
	}

	private bool filter_game (Game game) {
		if (game_filter != null && !game_filter (game))
			return false;

		return game.matches_search_terms (filtering_terms);
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
