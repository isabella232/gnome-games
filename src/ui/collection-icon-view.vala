// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-icon-view.ui")]
private class Games.CollectionIconView : Gtk.Bin {
	public signal void game_activated (Game game);

	private string[] filtering_terms;
	public string filtering_text {
		set {
			filtering_terms = value.split (" ");
			flow_box.invalidate_filter ();
		}
	}

	private Developer? _filtering_developer;
	public Developer? filtering_developer {
		set {
			_filtering_developer = value;
			flow_box.invalidate_filter ();
		}
		get { return _filtering_developer; }
	}

	private Platform? _filtering_platform;
	public Platform? filtering_platform {
		set {
			_filtering_platform = value;
			flow_box.invalidate_filter ();
		}
		get { return _filtering_platform; }
	}

	private ulong model_changed_id;
	private ListModel _model;
	public ListModel model {
		get { return _model; }
		set {
			if (model != null)
				model.disconnect (model_changed_id);

			_model = value;
			clear_content ();
			if (model == null)
				return;

			for (int i = 0 ; i < model.get_n_items () ; i++) {
				var game = model.get_item (i) as Game;
				add_game (game);
			}
			model_changed_id = model.items_changed.connect (on_items_changed);

			flow_box.invalidate_sort ();
		}
	}

	private Binding window_active_binding;
	private bool _is_active;
	public bool is_active {
		set {
			if (_is_active == value)
				return;

			_is_active = value;

			if (!_is_active)
				gamepad_browse.cancel_cursor_movement ();
		}
		get {
			return _is_active;
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
		flow_box.set_filter_func (filter_box);
		flow_box.set_sort_func (sort_boxes);
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

	public void reset_scroll_position () {
		var adjustment = scrolled_window.get_vadjustment ();
		adjustment.set_value (0);
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
		if (child.get_child () is GameIconView)
			on_game_view_activated (child.get_child () as GameIconView);
	}

	private void on_game_view_activated (GameIconView game_view) {
		game_activated (game_view.game);
	}

	private void on_items_changed (uint position, uint removed, uint added) {
		// FIXME: currently games are never removed, update this function if
		// necessary.
		assert (removed == 0);

		for (uint i = position ; i < position + added ; i++) {
			var game = model.get_item (i) as Game;
			add_game (game);
		}
	}

	private void add_game (Game game) {
		var game_view = new GameIconView (game);
		var child = new Gtk.FlowBoxChild ();

		game_view.visible = true;
		child.visible = true;

		child.add (game_view);
		flow_box.add (child);
	}

	private void clear_content () {
		flow_box.forall ((child) => { flow_box.remove (child); });
	}

	private bool filter_box (Gtk.FlowBoxChild child) {
		var game_view = child.get_child () as GameIconView;
		if (game_view == null)
			return false;

		if (game_view.game == null)
			return false;

		return filter_game (game_view.game);
	}

	private bool filter_game (Game game) {
		if (filtering_developer != null &&
		    filtering_developer.get_developer() != game.get_developer().get_developer())
			return false;

		if (filtering_platform != null &&
		    filtering_platform.get_name() != game.get_platform().get_name())
			return false;

		if (filtering_terms.length != 0)
			foreach (var term in filtering_terms)
				if (!(term.casefold () in game.name.casefold ()))
					return false;

		return true;
	}

	private int sort_boxes (Gtk.FlowBoxChild child1, Gtk.FlowBoxChild child2) {
		var game_view1 = child1.get_child () as GameIconView;
		var game_view2 = child2.get_child () as GameIconView;

		assert (game_view1 != null);
		assert (game_view2 != null);

		return sort_games (game_view1.game, game_view2.game);
	}

	private int sort_games (Game game1, Game game2) {
		return game1.name.collate (game2.name);
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
