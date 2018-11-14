public class Games.LibretroInputCapabilities : Object, InputCapabilities {
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
