// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/gamepad-mapper.ui")]
private class Games.GamepadMapper : Gtk.Box {
	public signal void finished (string sdl_string);

	[GtkChild]
	private GamepadView gamepad_view;
	[GtkChild]
	private Gtk.Label info_message;

	private Manette.Device device;
	private GamepadMappingBuilder mapping_builder;
	private GamepadInput[] mapping_inputs;
	private GamepadInput input;
	private uint current_input_index;

	private ulong gamepad_event_handler_id;

	public GamepadMapper (Manette.Device device, GamepadViewConfiguration configuration, GamepadInput[] mapping_inputs) {
		this.device = device;
		this.mapping_inputs = mapping_inputs;
		try {
			gamepad_view.set_configuration (configuration);
		}
		catch (Error e) {
			critical ("Could not set up gamepad view: %s", e.message);
		}
	}

	public void start () {
		mapping_builder = new GamepadMappingBuilder ();
		current_input_index = 0;
		connect_to_gamepad ();

		next_input ();
	}

	public void stop () {
		disconnect_from_gamepad ();
	}

	[GtkCallback]
	private void on_skip_clicked () {
		next_input ();
	}

	private void connect_to_gamepad () {
		gamepad_event_handler_id = device.event.connect (on_event);
	}

	private void disconnect_from_gamepad () {
		if (gamepad_event_handler_id != 0) {
			device.disconnect (gamepad_event_handler_id);
			gamepad_event_handler_id = 0;
		}
	}

	private void on_event (Manette.Event event) {
		switch (event.get_event_type ()) {
		case Manette.EventType.EVENT_BUTTON_RELEASE:
			if (input.type == EventCode.EV_ABS)
				return;

			if (!mapping_builder.set_button_mapping ((uint8) event.get_hardware_index (),
				                                     input))
				return;

			break;
		case Manette.EventType.EVENT_ABSOLUTE:
			uint16 axis;
			double value;

			if (!event.get_absolute (out axis, out value))
				return;

			if (-0.8 < value < 0.8)
				return;

			if (!mapping_builder.set_axis_mapping ((uint8) event.get_hardware_index (),
			                                       input))
				return;

			break;
		case Manette.EventType.EVENT_HAT:
			uint16 axis;
			int8 value;

			if (!event.get_hat (out axis, out value))
				return;

			if (value == 0)
				return;

			if (!mapping_builder.set_hat_mapping ((uint8) event.get_hardware_index (),
			                                      value,
			                                      input))
				return;

			break;
		default:
			return;
		}

		next_input ();
	}

	private void next_input () {
		if (current_input_index == mapping_inputs.length) {
			var sdl_string = mapping_builder.build_sdl_string ();
			finished (sdl_string);

			return;
		}

		gamepad_view.reset ();
		input = mapping_inputs[current_input_index++];
		gamepad_view.highlight (input, true);

		update_info_message ();
	}

	private void update_info_message () {
		switch (input.type) {
		case EventCode.EV_KEY:
			info_message.label = _("Press suitable button on your gamepad");

			break;
		case EventCode.EV_ABS:
			if (input.code == EventCode.ABS_X || input.code == EventCode.ABS_RX)
				info_message.label = _("Move suitable axis left/right on your gamepad");
			else if (input.code == EventCode.ABS_Y || input.code == EventCode.ABS_RY)
				info_message.label = _("Move suitable axis up/down on your gamepad");

			break;
		default:
			break;
		}
	}
}
