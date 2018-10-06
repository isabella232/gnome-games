// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseRating : Object, Rating {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseRating (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.rating_loaded)
			has_loaded = true;
		else {
			metadata.notify["rating-loaded"].connect (on_rating_loaded);
			metadata.get_rating ();
		}
	}

	private void on_rating_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.rating_loaded;
	}

	public float get_rating () {
		return metadata.get_rating ();
	}
}
