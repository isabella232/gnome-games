// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyGenre : Object, Genre {
	// This is needed because get_genre() can't transfer ownership of the list.
	private string[] genres;

	construct {
		genres = {};
	}

	public unowned string[] get_genre () {
		return genres;
	}
}
