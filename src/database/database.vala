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

	private Sqlite.Statement add_game_query;
	private Sqlite.Statement add_game_uri_query;
	private Sqlite.Statement update_game_query;
	private Sqlite.Statement delete_game_query;
	private Sqlite.Statement delete_uri_query;

	private Sqlite.Statement find_game_uris_query;
	private Sqlite.Statement get_cached_game_query;
	private Sqlite.Statement list_cached_games_query;

	private Sqlite.Statement add_game_resource_query;
	private Sqlite.Statement has_uri_query;

	public Database (string path) throws Error {
		if (Sqlite.Database.open (path, out database) != Sqlite.OK)
			throw new DatabaseError.COULDNT_OPEN ("Couldn’t open the database for “%s”.", path);

		exec (CREATE_RESOURCES_TABLE_QUERY, null);
		exec (CREATE_GAMES_TABLE_QUERY, null);
		exec (CREATE_URIS_TABLE_QUERY, null);

		add_game_query = prepare (database, ADD_GAME_QUERY);
		add_game_uri_query = prepare (database, ADD_GAME_URI_QUERY);
		update_game_query = prepare (database, UPDATE_GAME_QUERY);
		delete_game_query = prepare (database, DELETE_GAME_QUERY);
		delete_uri_query = prepare (database, DELETE_URI_QUERY);

		find_game_uris_query = prepare (database, FIND_GAME_URIS_QUERY);
		get_cached_game_query = prepare (database, GET_CACHED_GAME_QUERY);
		list_cached_games_query = prepare (database, LIST_CACHED_GAMES_QUERY);

		add_game_resource_query = prepare (database, ADD_GAME_RESOURCE_QUERY);
		has_uri_query = prepare (database, HAS_URI_QUERY);
	}

	public void add_uri (Uri uri) throws Error {
		if (has_uri (uri))
			return;

		add_game_resource_query.reset ();
		bind_text (add_game_resource_query, "$URI", uri.to_string ());

		if (add_game_resource_query.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Execution failed.");
	}

	public bool has_uri (Uri uri) throws Error {
		has_uri_query.reset ();
		bind_text (has_uri_query, "$URI", uri.to_string ());

		switch (has_uri_query.step ()) {
		case Sqlite.ROW:
			return has_uri_query.column_text (0) == "1";
		default:
			debug ("Execution failed.");

			return false;
		}
	}

	public DatabaseUriSource get_uri_source () {
		return new DatabaseUriSource (database);
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
		add_game_uri_query.reset ();
		bind_text (add_game_uri_query, "$UID", uid);
		bind_text (add_game_uri_query, "$URI", uri);

		var result = add_game_uri_query.step ();
		if (result != Sqlite.DONE && result != Sqlite.CONSTRAINT)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't add uri (%s, %s)", uid, uri);
	}

	public Game? store_game (Game game) throws Error {
		var uid = game.uid.get_uid ();
		var uri = game.uri.to_string ();
		var title = game.name;
		var platform = game.platform.get_id ();
		var media_set = serialize_media_set (game);

		// TODO transaction

		if (game.get_media_set () != null)
			foreach (var media_uri in get_media_uris (game))
				store_game_uri (uid, media_uri);
		else
			store_game_uri (uid, uri);

		add_game_query.reset ();
		bind_text (add_game_query, "$UID", uid);
		bind_text (add_game_query, "$TITLE", title);
		bind_text (add_game_query, "$PLATFORM", platform);
		bind_text (add_game_query, "$MEDIA_SET", media_set);

		var result = add_game_query.step ();
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
		var uid = game.uid.get_uid ();
		var uri = game.uri.to_string ();
		var title = game.name;
		var media_set = serialize_media_set (game);
		var old_title = prev_game != null ? prev_game.name : null;
		var old_media_set = prev_game != null ? serialize_media_set (prev_game) : null;

		if (old_title == title && old_media_set == media_set)
			return;

		update_game_query.reset ();
		bind_text (update_game_query, "$UID", uid);
		bind_text (update_game_query, "$TITLE", title);
		bind_text (update_game_query, "$MEDIA_SET", media_set);

		if (update_game_query.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't update game (%s, %s, %s)", uid, title, media_set);

		if (game.get_media_set () != null)
			foreach (var media_uri in get_media_uris (game))
				store_game_uri (uid, media_uri);
		else
			store_game_uri (uid, uri);
	}

	public bool remove_game (string uri, Game game) throws Error {
		var uid = game.uid.get_uid ();

		delete_uri_query.reset ();
		bind_text (delete_uri_query, "$URI", uri);

		if (delete_uri_query.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't delete uri (%s)", uri);

		find_game_uris_query.reset ();
		bind_text (find_game_uris_query, "$UID", uid);

		var result = find_game_uris_query.step ();
		if (result == Sqlite.ROW)
			return false;

		if (result != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't find uris (%s)", uid);

		delete_game_query.reset ();
		bind_text (delete_game_query, "$UID", uid);

		if (delete_game_query.step () != Sqlite.DONE)
			throw new DatabaseError.EXECUTION_FAILED ("Couldn't delete game (%s)", uid);

		return true;
	}

	private Game get_cached_game (string uid) throws Error {
		get_cached_game_query.reset ();
		bind_text (get_cached_game_query, "$UID", uid);

		if (get_cached_game_query.step () == Sqlite.ROW) {
			var uri = get_cached_game_query.column_text (0);
			var title = get_cached_game_query.column_text (1);
			var platform = get_cached_game_query.column_text (2);
			var media_set = get_cached_game_query.column_text (3);

			return create_game (uid, uri, title, platform, media_set);
		}

		throw new DatabaseError.EXECUTION_FAILED ("Couldn't get game for uid (%s)", uid);
	}

	public void list_cached_games (GameCallback game_callback) throws Error {
		list_cached_games_query.reset ();

		while (list_cached_games_query.step () == Sqlite.ROW) {
			var uid = list_cached_games_query.column_text (0);
			var uri = list_cached_games_query.column_text (1);
			var title = list_cached_games_query.column_text (2);
			var platform = list_cached_games_query.column_text (3);
			var media_set = list_cached_games_query.column_text (4);

			var game = create_game (uid, uri, title, platform, media_set);
			game_callback (game);
		}
	}

	private Game create_game (string uid, string uri, string title, string platform, string? media_set) {
		var game_uid = new Uid (uid);
		var game_uri = new Uri (uri);
		var game_title = new GenericTitle (title);
		var game_platform = PlatformRegister.get_register ().get_platform (platform);

		if (game_platform == null)
			game_platform = new DummyPlatform ();

		var game = new Game (game_uid, game_uri, game_title, game_platform);

		if (media_set != null)
			game.set_media_set (new MediaSet.parse (new Variant.parsed (media_set)));

		return game;
	}
}
