// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.ControllerSet : Object {
	public signal void changed ();
	public signal void reset ();

	public bool has_multiple_inputs {
		get {
			return has_keyboard && gamepads.length > 0
			|| gamepads.length > 1;
		}
	}

	public bool has_keyboard {
		get { return keyboard_port != uint.MAX; }
	}

	public bool has_gamepads {
		get { return gamepads.length > 0; }
	}

	public uint first_unplugged_port {
		get {
			uint i = 0;
			while (gamepads.contains (i) || i == keyboard_port) {
				i++;
			}
			return i;
		}
	}

	public uint keyboard_port {	set; get; }
	public HashTable<uint, Gamepad?> gamepads { set; get; }

	construct {
		keyboard_port = uint.MAX;
		gamepads = new HashTable<uint, Gamepad?> (GLib.direct_hash, GLib.direct_equal);
		notify["gamepads"].connect (() => changed ());
		notify["keyboard-port"].connect (() => changed ());
	}

	public void add_gamepad (uint port, Gamepad gamepad) {
		gamepads.insert (port, gamepad);

		changed ();
	}

	public void remove_gamepad (uint port) {
		gamepads.remove (port);

		changed ();
	}
}
