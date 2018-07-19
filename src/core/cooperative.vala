// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Cooperative : Object {
	public signal void changed ();

	public abstract bool get_cooperative ();
}
