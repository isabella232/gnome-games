// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Developer : Object {
	public signal void changed ();

	public abstract string get_developer ();

	public static uint hash (Developer developer) {
		return str_hash (developer.get_developer ());
	}

	public static bool equal (Developer a, Developer b) {
		return str_equal (a.get_developer (), b.get_developer ());
	}
}
