// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyReleaseDate : Object, ReleaseDate {
	public bool has_loaded { get; protected set; }

	public DateTime get_release_date () {
		return null;
	}
}
