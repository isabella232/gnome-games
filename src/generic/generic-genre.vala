// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericGenre : Object, Genre {
	private List<string> genre;

	public GenericGenre (List<string> genre) {
		this.genre = genre.copy ();
	}

	public unowned List<string> get_genre () {
		return genre;
	}
}
