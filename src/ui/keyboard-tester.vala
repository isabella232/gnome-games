// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/keyboard-tester.ui")]
private class Games.KeyboardTester : Gtk.Bin {
	[GtkChild]
	private GamepadView gamepad_view;

	private Gtk.EventControllerKey controller;

	public Retro.KeyJoypadMapping mapping { get; set; }

	private GamepadViewConfiguration _configuration;
	public GamepadViewConfiguration configuration {
		get { return _configuration; }
		construct {
			_configuration = value;
			gamepad_view.configuration = value;
		}
	}

	construct {
		controller = new Gtk.EventControllerKey ();
		controller.key_pressed.connect (on_key_press_event);
		controller.key_released.connect (on_key_release_event);
	}

	public KeyboardTester (GamepadViewConfiguration configuration) {
		Object (configuration: configuration);
	}

	public void start () {
		gamepad_view.reset ();
		connect_to_keyboard ();
	}

	public void stop () {
		disconnect_from_keyboard ();
	}

	private void connect_to_keyboard () {
		get_toplevel ().add_controller (controller);
	}

	private void disconnect_from_keyboard () {
		get_toplevel ().remove_controller (controller);
	}

	private bool on_key_press_event (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
		update_gamepad_view (keycode, true);

		return true;
	}

	private void on_key_release_event (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
		update_gamepad_view (keycode, false);
	}

	private void update_gamepad_view (uint keycode, bool highlight) {
		for (Retro.JoypadId joypad_id = 0; joypad_id < Retro.JoypadId.COUNT; joypad_id += 1) {
			if (mapping.get_button_key (joypad_id) == keycode) {
				var code = joypad_id.to_button_code ();
				gamepad_view.highlight ({ EventCode.EV_KEY, code }, highlight);
			}
		}
	}
}
