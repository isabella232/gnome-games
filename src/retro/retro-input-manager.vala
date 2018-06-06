// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroInputManager : Object {
	private Retro.Core core;
	private Retro.Controller core_view_joypad;
	private KeyboardMappingManager keyboard_mapping_manager;
	private Manette.Monitor monitor;
	private Retro.Controller?[] controllers;
	private int core_view_joypad_port;
	private bool present_analog_sticks;

	public RetroInputManager (Retro.Core core, Retro.CoreView view, bool present_analog_sticks) {
		this.core = core;
		this.present_analog_sticks = present_analog_sticks;

		keyboard_mapping_manager = new KeyboardMappingManager ();
		view.set_key_joypad_mapping (keyboard_mapping_manager.mapping);
		keyboard_mapping_manager.changed.connect (() => {
			view.set_key_joypad_mapping (keyboard_mapping_manager.mapping);
		});
		core_view_joypad = view.as_controller (Retro.ControllerType.JOYPAD);
		core.set_keyboard (view);
		view.set_as_default_controller (core);

		monitor = new Manette.Monitor ();
		var iterator = monitor.iterate ();
		Manette.Device device = null;
		while (iterator.next (out device)) {
			var port = controllers.length;
			var retro_gamepad = new RetroGamepad (device, present_analog_sticks);
			controllers += retro_gamepad;
			core.set_controller (port, retro_gamepad);
			device.disconnected.connect (() => on_device_disconnected (port));
		};

		core_view_joypad_port = controllers.length;
		controllers += core_view_joypad;
		core.set_controller (core_view_joypad_port, core_view_joypad);
		monitor.device_connected.connect (on_device_connected);
	}

	private void on_device_connected (Manette.Device device) {
		// Plug this device to the port where the CoreView's joypad was
		// connected as a last resort.
		var port = core_view_joypad_port;
		var retro_gamepad = new RetroGamepad (device, present_analog_sticks);
		controllers[port] = retro_gamepad;
		core.set_controller (port, retro_gamepad);
		device.disconnected.connect (() => on_device_disconnected (port));

		// Assign the CoreView's joypad to another disconnected port if it
		// exists and return.
		for (var i = core_view_joypad_port; i < controllers.length; i++) {
			if (controllers[i] == null) {
				// Found an disconnected port and so assigning core_view_joypad to it
				core_view_joypad_port = i;
				controllers[core_view_joypad_port] = core_view_joypad;
				core.set_controller (core_view_joypad_port, core_view_joypad);

				return;
			}
		}

		// Now it means that there is no disconnected port so append the
		// CoreView's joypad to ports.
		core_view_joypad_port = controllers.length;
		controllers += core_view_joypad;
		core.set_controller (core_view_joypad_port, core_view_joypad);
	}

	private void on_device_disconnected (int port) {
		if (core_view_joypad_port > port) {
			// Remove the controller and shift the CoreView's joypad to
			// "lesser" port.
			controllers[core_view_joypad_port] = null;
			core_view_joypad_port = port;
			controllers[core_view_joypad_port] = core_view_joypad;
			core.set_controller (core_view_joypad_port, core_view_joypad);
		}
		else {
			// Just remove the controller as no need to shift the
			// CoreView's joypad.
			controllers[port] = null;
			core.set_controller (port, null);
		}
	}
}
