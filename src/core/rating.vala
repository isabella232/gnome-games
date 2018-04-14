// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Rating : Object {
	public signal void changed ();

	public abstract float get_rating ();
}
