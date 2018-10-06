// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabasePlayers : Object, Players {
	private DatabaseMetadata metadata;

	public bool has_loaded { get; protected set; }

	public DatabasePlayers (DatabaseMetadata metadata) {
		this.metadata = metadata;

		if (metadata.players_loaded)
			has_loaded = true;
		else {
			metadata.notify["players-loaded"].connect (on_players_loaded);
			metadata.get_players ();
		}
	}

	private void on_players_loaded (Object object, ParamSpec param) {
		has_loaded = metadata.players_loaded;
	}

	public string get_players () {
		return metadata.get_players ();
	}
}
