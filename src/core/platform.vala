// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Platform : Object {
	public abstract string get_id ();

	public abstract string get_name ();

	public abstract string get_uid_prefix ();

	public abstract Gtk.ListBoxRow get_row ();

	public abstract Type get_snapshot_type ();

	public static uint hash (Platform platform) {
		return str_hash (platform.get_id ());
	}

	public static bool equal (Platform a, Platform b) {
		return a == b || str_equal (a.get_id (), b.get_id ());
	}

	public static int compare (Platform a, Platform b) {
		return a.get_name ().collate (b.get_name ());
	}

	public string get_system_dir () {
		var platforms_dir = Application.get_platforms_dir ();
		var id = get_id ();

		return @"$platforms_dir/$id/system";
	}

}
