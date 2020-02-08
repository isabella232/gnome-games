// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-icon-view.ui")]
private class Games.CollectionIconView : Gtk.Bin {
	public signal void game_activated (Game game);

	private string[] filtering_terms;

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

			game_model.items_changed.connect (apply_filter);
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

	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;
	[GtkChild]
	private Gtk.FlowBox flow_box;

	[GtkChild]
	private GamepadBrowse gamepad_browse;

	static construct {
		set_css_name ("gamescollectioniconview");
	}

	construct {
		flow_box.max_children_per_line = uint.MAX;
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
		apply_filter ();
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
	private void on_child_activated (Gtk.FlowBoxChild child) {
		var game_view = child.get_child () as GameIconView;

		game_activated (game_view.game);
	}

	private Gtk.Widget add_game (Object item) {
		var game = item as Game;

		var game_view = new GameIconView (game);
		game_view.show ();

		return game_view;
	}

	public void apply_filter () {
		flow_box.foreach (widget => {
			var child = widget as Gtk.FlowBoxChild;
			var game_view = child.get_child () as GameIconView;

			widget.visible = filter_game (game_view.game);
		});
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
