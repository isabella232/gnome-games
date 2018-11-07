// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/input-mode-switcher.ui")]
private class Games.InputModeSwitcher : Gtk.Box {
	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			_runner = value;

			if (value == null) {
				visible = false;
				return;
			}

			runner.notify["input-mode"].connect (on_input_mode_changed);
			visible = (value.get_available_input_modes ().length >= 2);
			on_input_mode_changed ();
		}
	}

	private void on_input_mode_changed () {
		switch (runner.input_mode) {
		case InputMode.GAMEPAD:
			gamepad_mode.active = true;

			break;
		case InputMode.KEYBOARD:
			keyboard_mode.active = true;

			break;
		}
	}

	[GtkChild]
	private Gtk.RadioButton keyboard_mode;
	[GtkChild]
	private Gtk.RadioButton gamepad_mode;

	[GtkCallback]
	private void on_keyboard_button_toggled () {
		if (keyboard_mode.active)
			runner.input_mode = InputMode.KEYBOARD;
	}

	[GtkCallback]
	private void on_gamepad_button_toggled () {
		if (gamepad_mode.active)
			runner.input_mode = InputMode.GAMEPAD;
	}
}
