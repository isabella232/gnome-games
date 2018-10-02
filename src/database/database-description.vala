// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseDescription : Object, Description {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseDescription (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.description_loaded)
			has_loaded = true;
		else {
			metadata.notify["description-loaded"].connect (on_description_loaded);
			metadata.get_description ();
		}
	}

	private void on_description_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.description_loaded;
	}

	public string get_description () {
		return metadata.get_description ();
	}
}
