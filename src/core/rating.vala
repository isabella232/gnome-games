// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Rating : Object {
	public abstract bool has_loaded { get; protected set; }

	public abstract float get_rating ();
}
