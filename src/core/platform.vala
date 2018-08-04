// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Platform : Object {
	public abstract string get_id ();

	public abstract string get_name ();

	public static uint hash (Platform platform) {
		return str_hash (platform.get_name ());
	}

	public static bool equal (Platform a, Platform b) {
		return str_equal (a.get_name (), b.get_name ());
	}
}
