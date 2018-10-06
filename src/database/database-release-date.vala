// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseReleaseDate : Object, ReleaseDate {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseReleaseDate (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.release_date_loaded)
			has_loaded = true;
		else {
			metadata.notify["release-date-loaded"].connect (on_release_date_loaded);
			metadata.get_release_date ();
		}
	}

	private void on_release_date_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.release_date_loaded;
	}

	public DateTime get_release_date () {
		return metadata.get_release_date ();
	}
}
