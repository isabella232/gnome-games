// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabasePublisher : Object, Publisher {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabasePublisher (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.publisher_loaded)
			has_loaded = true;
		else {
			metadata.notify["publisher-loaded"].connect (on_publisher_loaded);
			metadata.get_publisher ();
		}
	}

	private void on_publisher_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.publisher_loaded;
	}

	public string get_publisher () {
		return metadata.get_publisher ();
	}
}
