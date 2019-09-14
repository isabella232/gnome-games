// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseGame : Object, Game {
	public string name {
		get { return game.name; }
	}

	private Database database;
	private Game game;

	public DatabaseGame (Database database, Game game) {
		this.database = database;
		this.game = game;
	}

	public Uid get_uid () {
		return database.get_uid (game.get_uid ());
	}

	public Icon get_icon () {
		return game.get_icon ();
	}

	public Cover get_cover () {
		return game.get_cover ();
	}

	public Platform get_platform () {
		return game.get_platform ();
	}

	public Runner get_runner () throws Error {
		return game.get_runner ();
	}
}
