// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyReleaseDate : Object, ReleaseDate {
	public DateTime get_release_date () {
		return new DateTime.utc (1970, 1, 1, 0, 0, 0);
	}
}
