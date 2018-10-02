// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Genre : Object {
	public abstract bool has_loaded { get; protected set; }

	public abstract unowned string[] get_genre ();
}
