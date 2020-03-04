// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericInputCapabilities : Object, InputCapabilities {
	private bool allow_keyboard_mode;
	private bool allow_gamepad_mode;

	public GenericInputCapabilities (bool allow_keyboard_mode, bool allow_gamepad_mode = true) {
		this.allow_keyboard_mode = allow_keyboard_mode;
		this.allow_gamepad_mode = allow_gamepad_mode;
	}

	public bool get_allow_keyboard_mode () {
		return allow_keyboard_mode;
	}

	public bool get_allow_gamepad_mode () {
		return allow_gamepad_mode;
	}
}
