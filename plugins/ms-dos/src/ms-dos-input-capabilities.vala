// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.MsDosInputCapabilities : Object, InputCapabilities {
	public bool get_allow_classic_gamepads () throws Error {
		return true;
	}

	public bool get_allow_analog_gamepads () throws Error {
		return true;
	}

	public bool get_allow_keyboard_mode () {
		return true;
	}
}
