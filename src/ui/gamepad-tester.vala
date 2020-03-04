// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/gamepad-tester.ui")]
private class Games.GamepadTester : Gtk.Bin {
	[GtkChild]
	private GamepadView gamepad_view;

	private ulong gamepad_button_press_event_handler_id;
	private ulong gamepad_button_release_event_handler_id;
	private ulong gamepad_axis_event_handler_id;

	public Manette.Device device { get; construct; }

	private GamepadViewConfiguration _configuration;
	public GamepadViewConfiguration configuration {
		get { return _configuration; }
		construct {
			_configuration = value;
			gamepad_view.configuration = value;
		}
	}

	public GamepadTester (Manette.Device device, GamepadViewConfiguration configuration) {
		Object (device: device, configuration: configuration);
	}

	public void start () {
		gamepad_view.reset ();
		connect_to_gamepad ();
	}

	public void stop () {
		disconnect_from_gamepad ();
	}

	private void connect_to_gamepad () {
		gamepad_button_press_event_handler_id = device.button_press_event.connect (on_button_press_event);
		gamepad_button_release_event_handler_id = device.button_release_event.connect (on_button_release_event);
		gamepad_axis_event_handler_id = device.absolute_axis_event.connect (on_absolute_axis_event);
	}

	private void disconnect_from_gamepad () {
		if (gamepad_button_press_event_handler_id != 0) {
			device.disconnect (gamepad_button_press_event_handler_id);
			gamepad_button_press_event_handler_id = 0;
		}
		if (gamepad_button_release_event_handler_id != 0) {
			device.disconnect (gamepad_button_release_event_handler_id);
			gamepad_button_release_event_handler_id = 0;
		}
		if (gamepad_axis_event_handler_id != 0) {
			device.disconnect (gamepad_axis_event_handler_id);
			gamepad_axis_event_handler_id = 0;
		}
	}

	private void on_button_press_event (Manette.Event event) {
		uint16 button;

		if (event.get_button (out button))
			gamepad_view.highlight ({ EventCode.EV_KEY, button }, true);
	}

	private void on_button_release_event (Manette.Event event) {
		uint16 button;

		if (event.get_button (out button))
			gamepad_view.highlight ({ EventCode.EV_KEY, button }, false);
	}

	private void on_absolute_axis_event (Manette.Event event) {
		uint16 axis;
		double value;

		if (event.get_absolute (out axis, out value))
			gamepad_view.set_analog ({ EventCode.EV_ABS, axis }, value);
	}
}
