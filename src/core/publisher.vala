// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Publisher : Object {
	public abstract bool has_loaded { get; protected set; }

	public abstract string get_publisher ();
}
