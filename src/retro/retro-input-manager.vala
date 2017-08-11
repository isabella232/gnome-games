// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroInputManager : Retro.InputDeviceManager, Retro.Rumble {
	public ControllerSet controller_set { set; get; }

	private Retro.VirtualGamepad keyboard;
	private GamepadMonitor gamepad_monitor;
	private bool present_analog_sticks;

	construct {
		controller_set = new ControllerSet ();
		controller_set.reset.connect (reset);

		gamepad_monitor = GamepadMonitor.get_instance ();
		gamepad_monitor.gamepad_plugged.connect (add_gamepad);
	}

	public RetroInputManager (Gtk.Widget widget, bool present_analog_sticks) {
		this.present_analog_sticks = present_analog_sticks;

		// Assumption: keyboard always exists.
		keyboard = new Retro.VirtualGamepad (widget);
		set_keyboard (widget);
		controller_set.keyboard_port = 0;
		set_controller_device (controller_set.keyboard_port, keyboard);

		gamepad_monitor.foreach_gamepad (add_gamepad);
	}

	private void reset () {
		foreach_controller ((port, controller) => {
			remove_controller_device (port);
		});

		if (controller_set.has_gamepads) {
			controller_set.gamepads.foreach ((port, gamepad) => {
				var retro_gamepad = new RetroGamepad (gamepad, present_analog_sticks);
				set_controller_device (port, retro_gamepad);
			});
		}
		if (controller_set.has_keyboard)
			set_controller_device (controller_set.keyboard_port, keyboard);
	}

	private void add_gamepad (Gamepad gamepad) {
		// Plug this gamepad to the port where the keyboard was plugged
		var port = controller_set.keyboard_port;
		controller_set.add_gamepad (port, gamepad);
		var retro_gamepad = new RetroGamepad (gamepad, present_analog_sticks);
		set_controller_device (port, retro_gamepad);
		gamepad.unplugged.connect (() => remove_gamepad (port));

		// Assign keyboard to first unplugged port
		controller_set.keyboard_port = controller_set.first_unplugged_port;
		set_controller_device (controller_set.keyboard_port, keyboard);
	}

	private void remove_gamepad (uint port) {
		controller_set.remove_gamepad (port);
		remove_controller_device (port);

		if (controller_set.has_keyboard && controller_set.keyboard_port > port) {
			// Shift keyboard to lesser port
			remove_controller_device (controller_set.keyboard_port);
			controller_set.keyboard_port = port;
			set_controller_device (controller_set.keyboard_port, keyboard);
		}
	}

	private bool set_rumble_state (uint port, Retro.RumbleEffect effect, uint16 strength) {
		if (controller_set.gamepads.contains (port))
			return false;

		// TODO Transmit the rumble signal to the gamepad.

		return false;
	}
}
