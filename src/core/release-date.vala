// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.ReleaseDate : Object {
	public abstract bool has_loaded { get; protected set; }

	public abstract DateTime get_release_date ();
}
