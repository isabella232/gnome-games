// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/keyboard-mapper.ui")]
private class Games.KeyboardMapper : Gtk.Box {
	public signal void finished (Retro.KeyJoypadMapping mapping);

	[GtkChild]
	private GamepadView gamepad_view;
	[GtkChild]
	private Gtk.Label info_message;

	private KeyboardMappingBuilder mapping_builder;
	private GamepadInput[] mapping_inputs;
	private GamepadInput input;
	private uint current_input_index;

	construct {
		info_message.label = _("Press suitable key on your keyboard");
	}

	public KeyboardMapper (GamepadViewConfiguration configuration, GamepadInput[] mapping_inputs) {
		this.mapping_inputs = mapping_inputs;
		try {
			gamepad_view.set_configuration (configuration);
		}
		catch (Error e) {
			critical ("Could not set up gamepad view: %s", e.message);
		}
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

	[GtkCallback]
	private void on_skip_clicked () {
		next_input ();
	}

	private void connect_to_keyboard () {
		get_toplevel ().key_release_event.connect (on_keyboard_event);
	}

	private void disconnect_from_keyboard () {
		get_toplevel ().key_release_event.disconnect (on_keyboard_event);
	}

	private bool on_keyboard_event (Gdk.EventKey key) {
		if (mapping_builder.set_input_mapping (input, key.hardware_keycode))
			next_input ();

		return true;
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
