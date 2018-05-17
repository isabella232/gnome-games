// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericReleaseDate : Object, ReleaseDate {
	private DateTime release_date;

	public GenericReleaseDate (DateTime release_date) {
		this.release_date = release_date;
	}

	public DateTime get_release_date () {
		return release_date;
	}
}
