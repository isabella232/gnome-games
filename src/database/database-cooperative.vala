// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseCooperative : Object, Cooperative {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabaseCooperative (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.cooperative_loaded)
			has_loaded = true;
		else {
			metadata.notify["cooperative-loaded"].connect (on_cooperative_loaded);
			metadata.get_cooperative ();
		}
	}

	private void on_cooperative_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.cooperative_loaded;
	}

	public bool get_cooperative () {
		return metadata.get_cooperative ();
	}
}
