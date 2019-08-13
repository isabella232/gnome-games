// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Platform : Object {
	public abstract string get_id ();

	public abstract string get_name ();

	public abstract string get_uid_prefix ();

	public abstract PreferencesPagePlatformsRow get_row ();

	public abstract Type get_savestate_type ();

	public static uint hash (Platform platform) {
		return str_hash (platform.get_id ());
	}

	public static bool equal (Platform a, Platform b) {
		return a == b || str_equal (a.get_id (), b.get_id ());
	}

	public static int compare (Platform a, Platform b) {
		return a.get_name ().collate (b.get_name ());
	}
}
