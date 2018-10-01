// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseDeveloper : Object, Developer {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseDeveloper (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.developer_loaded)
			has_loaded = true;
		else {
			metadata.notify["developer-loaded"].connect (on_developer_loaded);
			metadata.get_developer ();
		}
	}

	private void on_developer_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.developer_loaded;
	}

	public string get_developer () {
		return metadata.get_developer ();
	}
}
