// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.Database : Object {
	private Sqlite.Database database;

	private const string CREATE_RESOURCES_TABLE_QUERY = """
		CREATE TABLE IF NOT EXISTS game_resources (
			id INTEGER PRIMARY KEY NOT NULL,
			uri TEXT NOT NULL
		);
	""";

	private const string CREATE_GAMES_TABLE_QUERY = """
		CREATE TABLE IF NOT EXISTS games (
			id INTEGER PRIMARY KEY NOT NULL,
			uid TEXT NOT NULL UNIQUE,
			title TEXT NOT NULL,
			platform TEXT NOT NULL,
			media_set TEXT NULL
		);
	""";

	private const string CREATE_URIS_TABLE_QUERY = """
		CREATE TABLE IF NOT EXISTS uris (
			id INTEGER PRIMARY KEY NOT NULL,
			uid TEXT NOT NULL,
			uri TEXT NOT NULL UNIQUE,
			FOREIGN KEY(uid) REFERENCES games(uid)
		);
	""";

	private const string ADD_GAME_QUERY = """
		INSERT INTO games (uid, title, platform, media_set) VALUES ($UID, $TITLE, $PLATFORM, $MEDIA_SET);
	""";

	private const string ADD_GAME_URI_QUERY = """
		INSERT INTO uris (uid, uri) VALUES ($UID, $URI);
	""";

	private const string UPDATE_GAME_QUERY = """
		UPDATE games SET title = $TITLE, media_set = $MEDIA_SET WHERE uid = $UID;
	""";

	private const string DELETE_GAME_QUERY = """
		DELETE FROM games WHERE uid = $UID;
	""";

	private const string DELETE_URI_QUERY = """
		DELETE FROM uris WHERE uri = $URI;
	""";

	private const string FIND_GAME_URIS_QUERY = """
		SELECT uri FROM uris WHERE uid = $UID;
	""";

	private const string GET_CACHED_GAME_QUERY = """
		SELECT uri, title, platform, media_set FROM games JOIN uris ON games.uid == uris.uid WHERE games.uid == $UID;
	""";

	private const string LIST_CACHED_GAMES_QUERY = """
		SELECT games.uid, uri, title, platform, media_set FROM games JOIN uris ON games.uid == uris.uid ORDER BY title;
	""";

	private const string ADD_GAME_RESOURCE_QUERY = """
		INSERT INTO game_resources (id, uri) VALUES (NULL, $URI);
	""";

	private const string HAS_URI_QUERY = """
		SELECT EXISTS (SELECT 1 FROM game_resources WHERE uri=$URI LIMIT 1);
	""";

	public Database (string path) throws Error {
		if (Sqlite.Database.open (path, out database) != Sqlite.OK)
			throw new DatabaseError.COULDNT_OPEN ("Couldn’t open the database for “%s”.", path);

		create_tables ();
	}

	public void add_uri (Uri uri) throws Error {
		if (has_uri (uri))
			return;

		var statement = prepare (database, ADD_GAME_RESOURCE_QUERY);

		bind_text (statement, "$URI", uri.to_string ());

		if (statement.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Execution failed.");
	}

	public bool has_uri (Uri uri) throws Error {
		var statement = prepare (database, HAS_URI_QUERY);

		bind_text (statement, "$URI", uri.to_string ());

		switch (statement.step ()) {
		case Sqlite.ROW:
			return statement.column_text (0) == "1";
		default:
			debug ("Execution failed.");

			return false;
		}
	}

	public DatabaseUriSource get_uri_source () {
		return new DatabaseUriSource (database);
	}

	private void create_tables () throws Error {
		exec (CREATE_RESOURCES_TABLE_QUERY, null);
		exec (CREATE_GAMES_TABLE_QUERY, null);
		exec (CREATE_URIS_TABLE_QUERY, null);
	}

	private void exec (string query, Sqlite.Callback? callback) throws Error {
		string error_message;

		if (database.exec (query, callback, out error_message) != Sqlite.OK)
			throw new DatabaseError.EXECUTION_FAILED ("Execution failed: %s", error_message);
	}

	internal static Sqlite.Statement prepare (Sqlite.Database database, string query) throws Error {
		Sqlite.Statement statement;
		if (database.prepare_v2 (query, query.length, out statement) != Sqlite.OK)
			throw new DatabaseError.PREPARATION_FAILED ("Preparation failed: %s", database.errmsg ());

		return statement;
	}

	internal static void bind_text (Sqlite.Statement statement, string parameter, string? text) throws Error {
		var position = statement.bind_parameter_index (parameter);
		if (position <= 0)
			throw new DatabaseError.BINDING_FAILED ("Couldn't bind text to the parameter “%s”, unexpected position: %d.", parameter, position);

		if (text != null)
			statement.bind_text (position, text);
		else
			statement.bind_null (position);
	}

	private string? serialize_media_set (Game game) {
		var media_set = game.get_media_set ();

		if (media_set == null)
			return null;

		return media_set.serialize ().print (true);
	}

	private string[] get_media_uris (Game game) {
		var media_set = game.get_media_set ();

		if (media_set == null)
			return {};

		string[] uris = {};
		media_set.foreach_media (media => {
			foreach (var uri in media.get_uris ())
				uris += uri.to_string ();
		});

		return uris;
	}

	private void store_game_uri (string uid, string uri) throws Error {
		var statement = prepare (database, ADD_GAME_URI_QUERY);
		bind_text (statement, "$UID", uid);
		bind_text (statement, "$URI", uri);

		var result = statement.step ();
		if (result != Sqlite.DONE && result != Sqlite.CONSTRAINT)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't add uri (%s, %s)", uid, uri);
	}

	public Game? store_game (Game game) throws Error {
		var uid = game.get_uid ().get_uid ();
		var uri = game.get_uri ().to_string ();
		var title = game.name;
		var platform = game.get_platform ().get_id ();
		var media_set = serialize_media_set (game);

		// TODO transaction

		if (game.get_media_set () != null)
			foreach (var media_uri in get_media_uris (game))
				store_game_uri (uid, media_uri);
		else
			store_game_uri (uid, uri);

		var statement = prepare (database, ADD_GAME_QUERY);
		bind_text (statement, "$UID", uid);
		bind_text (statement, "$TITLE", title);
		bind_text (statement, "$PLATFORM", platform);
		bind_text (statement, "$MEDIA_SET", media_set);

		var result = statement.step ();
		if (result == Sqlite.CONSTRAINT) {
			var prev_game = get_cached_game (uid);
			update_game (game, prev_game);
			return prev_game;
		}

		if (result != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't add game (%s, %s, %s, %s)", uid, title, platform, media_set);

		return null;
	}

	public void update_game (Game game, Game? prev_game = null) throws Error {
		var uid = game.get_uid ().get_uid ();
		var uri = game.get_uri ().to_string ();
		var title = game.name;
		var media_set = serialize_media_set (game);
		var old_title = prev_game != null ? prev_game.name : null;
		var old_media_set = prev_game != null ? serialize_media_set (prev_game) : null;

		if (old_title == title && old_media_set == media_set)
			return;

		var statement = prepare (database, UPDATE_GAME_QUERY);
		bind_text (statement, "$UID", uid);
		bind_text (statement, "$TITLE", title);
		bind_text (statement, "$MEDIA_SET", media_set);

		if (statement.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't update game (%s, %s, %s)", uid, title, media_set);

		if (game.get_media_set () != null)
			foreach (var media_uri in get_media_uris (game))
				store_game_uri (uid, media_uri);
		else
			store_game_uri (uid, uri);
	}

	public bool remove_game (string uri, Game game) throws Error {
		var uid = game.get_uid ().get_uid ();

		var statement = prepare (database, DELETE_URI_QUERY);
		bind_text (statement, "$URI", uri);

		if (statement.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't delete uri (%s)", uri);

		statement = prepare (database, FIND_GAME_URIS_QUERY);
		bind_text (statement, "$UID", uid);

		var result = statement.step ();
		if (result == Sqlite.ROW)
			return false;

		if (result != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't find uris (%s)", uid);

		statement = prepare (database, DELETE_GAME_QUERY);
		bind_text (statement, "$UID", uid);

		if (statement.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't delete game (%s)", uid);

		return true;
	}

	private Game get_cached_game (string game_uid) throws Error {
		var statement = prepare (database, GET_CACHED_GAME_QUERY);
		bind_text (statement, "$UID", game_uid);

		if (statement.step () == Sqlite.ROW) {
			var uid = statement.column_text (0);
			var uri = statement.column_text (1);
			var title = statement.column_text (2);
			var platform = statement.column_text (3);
			var media_set = statement.column_text (4);

			return new DatabaseGame (uid, uri, title, platform, media_set);
		}

		throw new DatabaseError.EXECUTION_FAILED ("Couldn't get game for uid (%s)", game_uid);
	}

	public void list_cached_games (GameCallback game_callback) throws Error {
		var statement = prepare (database, LIST_CACHED_GAMES_QUERY);

		while (statement.step () == Sqlite.ROW) {
			var uid = statement.column_text (0);
			var uri = statement.column_text (1);
			var title = statement.column_text (2);
			var platform = statement.column_text (3);
			var media_set = statement.column_text (4);

			var game = new DatabaseGame (uid, uri, title, platform, media_set);
			game_callback (game);
		}
	}
}
