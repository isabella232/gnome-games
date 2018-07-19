// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyGenre : Object, Genre {
	// This is needed because get_genre() can't transfer ownership of the list.
	private List<string> genres;

	construct {
		genres = new List<string> ();
	}

	public unowned List<string> get_genre () {
		return genres;
	}
}
