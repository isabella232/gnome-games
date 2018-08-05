// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GamepadBrowse : Object {
	private enum CursorMovementSource {
		UNKNOWN,
		DIRECTIONAL_PAD,
		ANALOG_STICK,
	}

	private const double DEAD_ZONE = 0.3;

	public signal bool browse (Gtk.DirectionType direction);
	public signal bool accept ();
	public signal bool cancel ();

	private Gtk.DirectionType cursor_direction;
	private CursorMovementSource cursor_movement_source;
	private Manette.Device? cursor_movement_device;
	private double cursor_speed;
	private uint cursor_timeout;

	public bool gamepad_button_press_event (Manette.Event event) {
		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_A:
			return accept ();
		case EventCode.BTN_B:
			return cancel ();
		case EventCode.BTN_START:
			return accept ();
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
		uint16 axis;
		double value;
		if (!event.get_absolute (out axis, out value))
			return false;

		// We square the value to get the speed so the progression is
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

		if (!browse (cursor_direction))
			return false;

		cursor_timeout = Timeout.add (500, setup_cursor_cb);

		return true;
	}

	private bool setup_cursor_cb () {
		if (cursor_speed == 0) {
			cancel_cursor_movement ();

			return false;
		}

		if (!browse (cursor_direction))
			return false;

		cursor_timeout = Timeout.add ((uint) (30 / cursor_speed), setup_cursor_cb);

		return false;
	}

	public void cancel_cursor_movement () {
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
}
