// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.KeyboardMappingBuilder : Object {
	public Retro.KeyJoypadMapping mapping { private set; get; }

	construct {
		mapping = new Retro.KeyJoypadMapping ();
	}

	public bool set_input_mapping (GamepadInput input, uint16 keycode) {
		var joypad_id = Retro.JoypadId.from_button_code (input.code);
		if (joypad_id == Retro.JoypadId.COUNT)
			return false;

		for (Retro.JoypadId i = 0; i < Retro.JoypadId.COUNT; i += 1)
			if (mapping.get_button_key (i) == keycode)
				return false;
		mapping.set_button_key (joypad_id, keycode);

		return true;
	}
}
