// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroInputManager : Object {
	private Retro.Core core;
	private Retro.CoreView view;
	private KeyboardMappingManager keyboard_mapping_manager;
	private Manette.Monitor monitor;
	private InputMode _input_mode;
	public InputMode input_mode {
		get { return _input_mode; }
		set {
			if (value == _input_mode)
				return;

			var core_view_joypad = view.as_controller (Retro.ControllerType.JOYPAD);

			_input_mode = value;
			switch (value) {
			case InputMode.GAMEPAD:
				core.set_keyboard (null);
				core.set_default_controller (Retro.ControllerType.JOYPAD, core_view_joypad);

				break;
			case InputMode.KEYBOARD:
				core.set_keyboard (view);
				core.set_default_controller (Retro.ControllerType.JOYPAD, null);

				break;
			case InputMode.NONE:
				core.set_keyboard (null);
				core.set_default_controller (Retro.ControllerType.JOYPAD, null);

				break;
			}
		}
	}

	// This is used only to compute the port on which a device is connected,
	// which is needed to not store it in closures which would also hold a
	// reference on the current object and create a reference cycle, leading to
	// a memory leak.
	private Manette.Device?[] devices;
	private Retro.Controller?[] controllers;
	private int core_view_joypad_port;
	private bool present_analog_sticks;

	public RetroInputManager (Retro.Core core, Retro.CoreView view, bool present_analog_sticks) {
		this.core = core;
		this.view = view;
		this.present_analog_sticks = present_analog_sticks;

		keyboard_mapping_manager = new KeyboardMappingManager ();
		view.set_key_joypad_mapping (keyboard_mapping_manager.mapping);
		keyboard_mapping_manager.changed.connect (on_keyboard_mapping_manager_changed);
		view.set_as_default_controller (core);
		input_mode = InputMode.GAMEPAD;

		monitor = new Manette.Monitor ();
		var iterator = monitor.iterate ();
		Manette.Device device = null;
		while (iterator.next (out device)) {
			var port = controllers.length;
			var retro_gamepad = new RetroGamepad (device, present_analog_sticks);
			devices += device;
			controllers += retro_gamepad;
			core.set_controller (port, retro_gamepad);
			device.disconnected.connect (on_device_disconnected);
		}

		core_view_joypad_port = controllers.length;
		devices += null;
		controllers += null;
		core.set_controller (core_view_joypad_port, null);
		monitor.device_connected.connect (on_device_connected);
	}

	~RetroInputManager () {
		// Break the reference cycle between the core and its view by unsetting
		// all the references of the view we gave to the core.
		core.set_keyboard (null);
		core.set_controller (core_view_joypad_port, null);
		for (int port = 0; port < controllers.length; port++)
			core.set_controller (port, null);
	}

	private void on_keyboard_mapping_manager_changed () {
		view.set_key_joypad_mapping (keyboard_mapping_manager.mapping);
	}

	private void on_device_connected (Manette.Device device) {
		// Plug this device to the port where the CoreView's joypad was
		// connected as a last resort.
		var port = core_view_joypad_port;
		devices[port] = device;
		var retro_gamepad = new RetroGamepad (device, present_analog_sticks);
		controllers[port] = retro_gamepad;
		core.set_controller (port, retro_gamepad);
		device.disconnected.connect (on_device_disconnected);

		// Assign the CoreView's joypad to another disconnected port if it
		// exists and return.
		for (var i = core_view_joypad_port; i < controllers.length; i++) {
			if (controllers[i] == null) {
				// Found an disconnected port and so assigning core_view_joypad to it
				core_view_joypad_port = i;
				devices[core_view_joypad_port] = null;
				controllers[core_view_joypad_port] = null;
				core.set_controller (core_view_joypad_port, null);

				return;
			}
		}

		// Now it means that there is no disconnected port so append the
		// CoreView's joypad to ports.
		core_view_joypad_port = controllers.length;
		devices += null;
		controllers += null;
		core.set_controller (core_view_joypad_port, null);
	}

	private void on_device_disconnected (Manette.Device device) {
		for (int port = 0; port < devices.length; port ++)
			if (devices[port] == device)
				disconnect_port (port);
	}

	private void disconnect_port (int port) {
		if (core_view_joypad_port > port) {
			// Remove the controller and shift the CoreView's joypad to
			// "lesser" port.
			devices[core_view_joypad_port] = null;
			controllers[core_view_joypad_port] = null;
			core_view_joypad_port = port;
			devices[core_view_joypad_port] = null;
			controllers[core_view_joypad_port] = null;
			core.set_controller (core_view_joypad_port, null);
		}
		else {
			// Just remove the controller as no need to shift the
			// CoreView's joypad.
			devices[port] = null;
			controllers[port] = null;
			core.set_controller (port, null);
		}
	}
}
