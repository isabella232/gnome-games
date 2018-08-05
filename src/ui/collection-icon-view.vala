// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-icon-view.ui")]
private class Games.CollectionIconView : Gtk.Stack {
	private enum CursorMovementSource {
		UNKNOWN,
		DIRECTIONAL_PAD,
		ANALOG_STICK,
	}

	private const double DEAD_ZONE = 0.3;

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

	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;
	[GtkChild]
	private Gtk.FlowBox flow_box;

	// Current size used by the thumbnails.
	private int game_view_size;

	private Gtk.DirectionType cursor_direction;
	private CursorMovementSource cursor_movement_source;
	private Manette.Device? cursor_movement_device;
	private double cursor_speed;
	private uint cursor_timeout;

	static construct {
		set_css_name ("gamescollectioniconview");
	}

	construct {
		flow_box.max_children_per_line = uint.MAX;
		flow_box.set_filter_func (filter_box);
		flow_box.set_sort_func (sort_boxes);
		unmap.connect (cancel_cursor_movement);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_A:
			flow_box.activate_cursor_child ();

			return true;
		case EventCode.BTN_START:
			flow_box.activate_cursor_child ();

			return true;
		case EventCode.BTN_DPAD_UP:
			return move_cursor (Gtk.DirectionType.UP, CursorMovementSource.DIRECTIONAL_PAD, event.get_device (), 1.0);
		case EventCode.BTN_DPAD_DOWN:
			return move_cursor (Gtk.DirectionType.DOWN, CursorMovementSource.DIRECTIONAL_PAD, event.get_device (), 1.0);
		case EventCode.BTN_DPAD_LEFT:
			return move_cursor (Gtk.DirectionType.LEFT, CursorMovementSource.DIRECTIONAL_PAD, event.get_device (), 1.0);
		case EventCode.BTN_DPAD_RIGHT:
			return move_cursor (Gtk.DirectionType.RIGHT, CursorMovementSource.DIRECTIONAL_PAD, event.get_device (), 1.0);
		default:
			return false;
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_DPAD_UP:
			if (cursor_movement_source != CursorMovementSource.DIRECTIONAL_PAD ||
			    cursor_movement_device != event.get_device ())
				return false;

			return cancel_cursor_movement_for_direction (Gtk.DirectionType.UP);
		case EventCode.BTN_DPAD_DOWN:
			if (cursor_movement_source != CursorMovementSource.DIRECTIONAL_PAD ||
			    cursor_movement_device != event.get_device ())
				return false;

			return cancel_cursor_movement_for_direction (Gtk.DirectionType.DOWN);
		case EventCode.BTN_DPAD_LEFT:
			if (cursor_movement_source != CursorMovementSource.DIRECTIONAL_PAD ||
			    cursor_movement_device != event.get_device ())
				return false;

			return cancel_cursor_movement_for_direction (Gtk.DirectionType.LEFT);
		case EventCode.BTN_DPAD_RIGHT:
			if (cursor_movement_source != CursorMovementSource.DIRECTIONAL_PAD ||
			    cursor_movement_device != event.get_device ())
				return false;

			return cancel_cursor_movement_for_direction (Gtk.DirectionType.RIGHT);
		default:
			return false;
		}
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		uint16 axis;
		double value;
		if (!event.get_absolute (out axis, out value))
			return false;

		// We quare the value to get the speed so the progression is
		// exponential. No need to compute the absolute value if we square it.
		switch (axis) {
		case EventCode.ABS_X:
			if (value > DEAD_ZONE)
				return move_cursor (Gtk.DirectionType.RIGHT, CursorMovementSource.ANALOG_STICK, event.get_device (), value * value);
			else if (value < -DEAD_ZONE)
				return move_cursor (Gtk.DirectionType.LEFT, CursorMovementSource.ANALOG_STICK, event.get_device (), value * value);
			else if (cursor_movement_source == CursorMovementSource.ANALOG_STICK &&
			         cursor_movement_device == event.get_device () &&
			         (cursor_direction == Gtk.DirectionType.LEFT || cursor_direction == Gtk.DirectionType.RIGHT))
				cancel_cursor_movement ();

			return false;
		case EventCode.ABS_Y:
			if (value > DEAD_ZONE)
				return move_cursor (Gtk.DirectionType.DOWN, CursorMovementSource.ANALOG_STICK, event.get_device (), value * value);
			else if (value < -DEAD_ZONE)
				return move_cursor (Gtk.DirectionType.UP, CursorMovementSource.ANALOG_STICK, event.get_device (), value * value);
			else if (cursor_movement_source == CursorMovementSource.ANALOG_STICK &&
			         cursor_movement_device == event.get_device () &&
			         (cursor_direction == Gtk.DirectionType.UP || cursor_direction == Gtk.DirectionType.DOWN))
				cancel_cursor_movement ();

			return false;
		case EventCode.ABS_RX:
			return false;
		case EventCode.ABS_RY:
			return false;
		default:
			return false;
		}
	}

	public void reset_scroll_position () {
		var adjustment = scrolled_window.get_vadjustment ();
		adjustment.set_value (0);
	}

	private bool apply_cursor_movement () {
		if (flow_box.get_selected_children ().length () == 0) {
			var first_child = flow_box.get_child_at_index (0);
			if (first_child == null)
				return false;

			flow_box.select_child (first_child);
			// This is needed to start moving the cursor with the gamepad only.
			first_child.focus (cursor_direction);

			return true;
		}

		switch (cursor_direction) {
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

	private bool move_cursor (Gtk.DirectionType direction, CursorMovementSource source, Manette.Device device, double speed) {
		cursor_movement_source = source;
		cursor_movement_device = device;
		cursor_speed = speed;

		if (cursor_timeout != 0 && cursor_direction == direction)
			return true;

		if (cursor_timeout != 0)
			Source.remove (cursor_timeout);

		cursor_timeout = 0;
		cursor_direction = direction;

		if (!apply_cursor_movement ())
			return false;

		cursor_timeout = Timeout.add (500, setup_cursor_cb);

		return true;
	}

	private bool setup_cursor_cb () {
		if (cursor_speed == 0) {
			cancel_cursor_movement ();

			return false;
		}

		if (!apply_cursor_movement ())
			return false;

		cursor_timeout = Timeout.add ((uint) (30 / cursor_speed), setup_cursor_cb);

		return false;
	}

	private void cancel_cursor_movement () {
		if (cursor_timeout != 0)
			Source.remove (cursor_timeout);

		cursor_movement_source = CursorMovementSource.UNKNOWN;
		cursor_movement_device = null;
		cursor_timeout = 0;

		return;
	}

	private bool cancel_cursor_movement_for_direction (Gtk.DirectionType direction) {
		if (cursor_direction != direction)
			return false;

		cancel_cursor_movement ();

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

		update_collection ();
	}

	private void add_game (Game game) {
		var game_view = new GameIconView (game);
		var child = new Gtk.FlowBoxChild ();

		game_view.visible = true;
		game_view.size = game_view_size;
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

	private void update_collection () {
		if (model.get_n_items () == 0)
			set_visible_child (empty_collection);
		else
			set_visible_child (scrolled_window);
	}

	[GtkCallback]
	private void on_size_allocate (Gtk.Allocation allocation) {
		// If the window's width is less than half the width of a 1920×1080
		// screen, display the game thumbnails at half the size to see more of
		// them rather than a few huge thumbnails, making Games more usable on
		// small screens.
		if (allocation.width < 960)
			set_size (128);
		else
			set_size (256);
	}

	private void set_size (int size) {
		if (game_view_size == size)
			return;

		game_view_size = size;

		flow_box.forall ((child) => {
			var flow_box_child = child as Gtk.FlowBoxChild;

			assert (flow_box_child != null);

			var game_view = flow_box_child.get_child () as GameIconView;

			assert (game_view != null);

			game_view.size = size;
		});
	}
}
