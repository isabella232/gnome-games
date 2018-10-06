// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseGenre : Object, Genre {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseGenre (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.genre_loaded)
			has_loaded = true;
		else {
			metadata.notify["genre-loaded"].connect (on_genre_loaded);
			metadata.get_genre ();
		}
	}

	private void on_genre_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.genre_loaded;
	}

	public unowned string[] get_genre () {
		return metadata.get_genre ();
	}
}
