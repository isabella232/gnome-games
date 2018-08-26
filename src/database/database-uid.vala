// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseUid : Object, Uid {
	private const string HAS_UID_QUERY = """
		SELECT EXISTS (SELECT 1 FROM game_metadata WHERE uid=$UID LIMIT 1);
	""";

	private const string ADD_UID_QUERY = """
		INSERT INTO game_metadata (uid) VALUES ($UID);
	""";

	private Uid uid;
	private Sqlite.Statement has_statement;
	private Sqlite.Statement add_statement;
	private bool has;

	internal DatabaseUid (Sqlite.Database database, Uid uid) {
		this.uid = uid;

		try {
			has_statement = Database.prepare (database, HAS_UID_QUERY);
			add_statement = Database.prepare (database, ADD_UID_QUERY);
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	public string get_uid () throws Error {
		try {
			if (!has)
				has_uid ();
			if (!has)
				add_uid ();
		}
		catch (Error e) {
			warning (e.message);
		}

		return uid.get_uid ();
	}

	private void has_uid () throws Error {
		if (has_statement == null)
			return;

		Database.bind_text (has_statement, "$UID", uid.get_uid ());

		if (has_statement.step () == Sqlite.ROW)
			has = has_statement.column_text (0) == "1";
		else
			warning ("Execution failed.");
	}

	private void add_uid () throws Error {
		if (add_statement == null)
			return;

		has = true;

		Database.bind_text (add_statement, "$UID", uid.get_uid ());

		if (add_statement.step () != Sqlite.DONE)
			warning ("Execution failed.");
	}
}
