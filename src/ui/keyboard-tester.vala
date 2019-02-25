// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/keyboard-tester.ui")]
private class Games.KeyboardTester : Gtk.Bin {
	[GtkChild]
	private GamepadView gamepad_view;

	public Retro.KeyJoypadMapping mapping { get; set; }

	private GamepadViewConfiguration _configuration;
	public GamepadViewConfiguration configuration {
		get { return _configuration; }
		construct {
			_configuration = value;
			gamepad_view.set_configuration (value);
		}
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
		var window = get_toplevel ();
		window.key_press_event.connect (on_key_press_event);
		window.key_release_event.connect (on_key_release_event);
	}

	private void disconnect_from_keyboard () {
		var window = get_toplevel ();
		window.key_press_event.disconnect (on_key_press_event);
		window.key_release_event.disconnect (on_key_release_event);
	}

	private bool on_key_press_event (Gdk.EventKey key) {
		update_gamepad_view (key, true);

		return true;
	}

	private bool on_key_release_event (Gdk.EventKey key) {
		update_gamepad_view (key, false);

		return true;
	}

	private void update_gamepad_view (Gdk.EventKey key, bool highlight) {
		for (Retro.JoypadId joypad_id = 0; joypad_id < Retro.JoypadId.COUNT; joypad_id += 1) {
			if (mapping.get_button_key (joypad_id) == key.hardware_keycode) {
				var code = joypad_id.to_button_code ();
				gamepad_view.highlight ({ EventCode.EV_KEY, code }, highlight);
			}
		}
	}
}
