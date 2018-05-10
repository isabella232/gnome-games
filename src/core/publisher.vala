// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Publisher : Object {
	public signal void changed ();

	public abstract string get_publisher ();
}
