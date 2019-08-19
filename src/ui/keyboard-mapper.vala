// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/keyboard-mapper.ui")]
private class Games.KeyboardMapper : Gtk.Bin {
	public signal void finished (Retro.KeyJoypadMapping mapping);

	[GtkChild]
	private GamepadView gamepad_view;

	private Gtk.EventControllerKey controller;

	private KeyboardMappingBuilder mapping_builder;
	private GamepadInput[] mapping_inputs;
	private GamepadInput input;
	private uint current_input_index;

	public string info_message { get; private set; }

	private GamepadViewConfiguration _configuration;
	public GamepadViewConfiguration configuration {
		get { return _configuration; }
		construct {
			_configuration = value;
			gamepad_view.configuration = value;
		}
	}

	construct {
		info_message = _("Press suitable key on your keyboard");

		controller = new Gtk.EventControllerKey ();
		controller.key_released.connect (on_keyboard_event);
	}

	public KeyboardMapper (GamepadViewConfiguration configuration, GamepadInput[] mapping_inputs) {
		Object (configuration: configuration);
		this.mapping_inputs = mapping_inputs;
	}

	public void start () {
		mapping_builder = new KeyboardMappingBuilder ();
		current_input_index = 0;
		connect_to_keyboard ();

		next_input ();
	}

	public void stop () {
		disconnect_from_keyboard ();
	}

	public void skip () {
		next_input ();
	}

	private void connect_to_keyboard () {
		var window = get_root () as Gtk.Window;
		window.add_controller (controller);
	}

	private void disconnect_from_keyboard () {
		var window = get_root () as Gtk.Window;
		window.remove_controller (controller);
	}

	private void on_keyboard_event (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
		if (mapping_builder.set_input_mapping (input, keycode))
			next_input ();
	}

	private void next_input () {
		if (current_input_index == mapping_inputs.length) {
			finished (mapping_builder.mapping);

			return;
		}

		gamepad_view.reset ();
		input = mapping_inputs[current_input_index++];
		gamepad_view.highlight (input, true);
	}
}
