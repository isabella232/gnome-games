// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.ReleaseDate : Object {
	public signal void changed ();

	public abstract DateTime get_release_date ();
}
