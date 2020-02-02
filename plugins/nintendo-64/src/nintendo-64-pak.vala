// This file is part of GNOME Games. License: GPL-3.0+.

public enum Games.Nintendo64Pak {
	MEMORY,
	RUMBLE,
	NONE;

	public string get_value () {
		switch (this) {
		case MEMORY:
			return "memory";

		case RUMBLE:
			return "rumble";

		case NONE:
			return "none";

		default:
			assert_not_reached ();
		}
	}

	public static Nintendo64Pak? from_value (string value) {
		switch (value) {
		case "memory":
			return MEMORY;

		case "rumble":
			return RUMBLE;

		case "none":
			return NONE;

		default:
			warning ("Unknown screen layout: %s\n", value);
			return null;
		}
	}
}
