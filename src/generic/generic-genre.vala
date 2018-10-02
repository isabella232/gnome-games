// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericGenre : Object, Genre {
	private string[] genre;

	public bool has_loaded { get; protected set; }

	construct {
		has_loaded = true;
	}

	public GenericGenre (string[] genre) {
		this.genre = genre.copy ();
	}

	public unowned string[] get_genre () {
		return genre;
	}
}
