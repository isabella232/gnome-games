// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseDeveloper : Object, Developer {
	private const string LOAD_DEVELOPER_QUERY = """
		SELECT developer FROM game_metadata WHERE uid=$UID;
	""";

	private const string SAVE_DEVELOPER_QUERY = """
		UPDATE game_metadata SET developer=$DEVELOPER WHERE uid=$UID;
	""";

	private Developer developer;
	private Uid uid;
	private Sqlite.Statement load_statement;
	private Sqlite.Statement save_statement;
	private string loaded;

	public bool has_loaded { get; protected set; }

	public DatabaseDeveloper (Sqlite.Database database, Developer developer, Uid uid) {
		this.developer = developer;
		this.uid = uid;

		developer.changed.connect (() => changed ());

		try {
			load_statement = Database.prepare (database, LOAD_DEVELOPER_QUERY);
			save_statement = Database.prepare (database, SAVE_DEVELOPER_QUERY);
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void on_developer_loaded () {
		if (!developer.has_loaded)
			return;

		has_loaded = true;

		try {
			save_developer ();
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	public string get_developer () {
		if (!has_loaded) {
			on_developer_loaded ();
			developer.notify["has-loaded"].connect (on_developer_loaded);
		}

		try {
			if (loaded == null)
				load_developer ();
			if (loaded != "" && loaded != null)
				return loaded;
		}
		catch (Error e) {
			warning (e.message);
		}

		return developer.get_developer ();
	}

	private void load_developer () throws Error {
		if (load_statement == null)
			return;

		Database.bind_text (load_statement, "$UID", uid.get_uid ());

		if (load_statement.step () == Sqlite.ROW)
			loaded = load_statement.column_text (0) ?? "";
		else
			warning ("Execution failed.");

		if (loaded != "" && loaded != null)
			has_loaded = true;
	}

	private void save_developer () throws Error {
		if (save_statement == null)
			return;

		loaded = developer.get_developer ();
		if (loaded == "")
			return;

		Database.bind_text (save_statement, "$UID", uid.get_uid ());
		Database.bind_text (save_statement, "$DEVELOPER", loaded);

		if (save_statement.step () != Sqlite.DONE)
			warning ("Execution failed.");
	}
}
