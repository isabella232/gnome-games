// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DatabaseMetadata : Object {
	private const string LOAD_QUERY = """
		SELECT
			cooperative,
			description,
			developer,
			genre,
			players,
			publisher,
			rating,
			release_date
		FROM game_metadata WHERE uid=$UID;
	""";

	private const string ADD_GAME_QUERY = """
		INSERT OR IGNORE INTO game_metadata (uid) VALUES ($UID);
	""";

	private const string SAVE_COOPERATIVE_QUERY = """
		UPDATE game_metadata SET cooperative=$COOPERATIVE WHERE uid=$UID;
	""";

	private const string SAVE_DESCRIPTION_QUERY = """
		UPDATE game_metadata SET description=$DESCRIPTION WHERE uid=$UID;
	""";

	private const string SAVE_DEVELOPER_QUERY = """
		UPDATE game_metadata SET developer=$DEVELOPER WHERE uid=$UID;
	""";

	private const string SAVE_GENRE_QUERY = """
		UPDATE game_metadata SET genre=$GENRE WHERE uid=$UID;
	""";

	private const string SAVE_PLAYERS_QUERY = """
		UPDATE game_metadata SET players=$PLAYERS WHERE uid=$UID;
	""";

	private const string SAVE_PUBLISHER_QUERY = """
		UPDATE game_metadata SET publisher=$PUBLISHER WHERE uid=$UID;
	""";

	private const string SAVE_RATING_QUERY = """
		UPDATE game_metadata SET rating=$RATING WHERE uid=$UID;
	""";

	private const string SAVE_RELEASE_DATE_QUERY = """
		UPDATE game_metadata SET release_date=$RELEASE_DATE WHERE uid=$UID;
	""";

	private Game game;
	private Uid uid;
	private Cooperative cooperative;
	private Description description;
	private Developer developer;
	private Genre genre;
	private Players players;
	private Publisher publisher;
	private Rating rating;
	private ReleaseDate release_date;

	private string uid_value;
	private bool cooperative_value;
	private string description_value;
	private string developer_value;
	private string[] genre_value;
	private string players_value;
	private string publisher_value;
	private float rating_value;
	private DateTime release_date_value;

	private Sqlite.Statement add_game_statement;
	private Sqlite.Statement load_statement;
	private Sqlite.Statement save_cooperative_statement;
	private Sqlite.Statement save_description_statement;
	private Sqlite.Statement save_developer_statement;
	private Sqlite.Statement save_genre_statement;
	private Sqlite.Statement save_players_statement;
	private Sqlite.Statement save_publisher_statement;
	private Sqlite.Statement save_rating_statement;
	private Sqlite.Statement save_release_date_statement;

	public bool cooperative_loaded { get; set; }
	public bool description_loaded { get; set; }
	public bool developer_loaded { get; set; }
	public bool genre_loaded { get; set; }
	public bool players_loaded { get; set; }
	public bool publisher_loaded { get; set; }
	public bool rating_loaded { get; set; }
	public bool release_date_loaded { get; set; }

	private bool game_added;

	public DatabaseMetadata (Sqlite.Database database, Game game) {
		this.game = game;

		uid = game.get_uid ();
		cooperative = game.get_cooperative ();
		description = game.get_description ();
		developer = game.get_developer ();
		genre = game.get_genre ();
		players = game.get_players ();
		publisher = game.get_publisher ();
		rating = game.get_rating ();
		release_date = game.get_release_date ();

		try {
			uid_value = game.get_uid ().get_uid ();

			add_game_statement = Database.prepare (database, ADD_GAME_QUERY);
			load_statement = Database.prepare (database, LOAD_QUERY);
			save_cooperative_statement = Database.prepare (database, SAVE_COOPERATIVE_QUERY);
			save_description_statement = Database.prepare (database, SAVE_DESCRIPTION_QUERY);
			save_developer_statement = Database.prepare (database, SAVE_DEVELOPER_QUERY);
			save_genre_statement = Database.prepare (database, SAVE_GENRE_QUERY);
			save_players_statement = Database.prepare (database, SAVE_PLAYERS_QUERY);
			save_publisher_statement = Database.prepare (database, SAVE_PUBLISHER_QUERY);
			save_rating_statement = Database.prepare (database, SAVE_RATING_QUERY);
			save_release_date_statement = Database.prepare (database, SAVE_RELEASE_DATE_QUERY);

			load_metadata ();
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	public bool get_cooperative () {
		if (!cooperative_loaded) {
			on_cooperative_loaded ();
			cooperative.notify.connect (on_cooperative_loaded);
			return cooperative.get_cooperative ();
		}

		return cooperative_value;
	}

	public string get_description () {
		if (!description_loaded) {
			on_description_loaded ();
			description.notify.connect (on_description_loaded);
			return description.get_description ();
		}

		return description_value;
	}

	public string get_developer () {
		if (!developer_loaded) {
			on_developer_loaded ();
			developer.notify.connect (on_developer_loaded);
			return developer.get_developer ();
		}

		return developer_value;
	}

	public unowned string[] get_genre () {
		if (!genre_loaded) {
			on_genre_loaded ();
			genre.notify.connect (on_genre_loaded);
			return genre.get_genre ();
		}

		return genre_value;
	}

	public string get_players () {
		if (!players_loaded) {
			on_players_loaded ();
			players.notify.connect (on_players_loaded);
			return players.get_players ();
		}

		return players_value;
	}

	public string get_publisher () {
		if (!publisher_loaded) {
			on_publisher_loaded ();
			publisher.notify.connect (on_publisher_loaded);
			return publisher.get_publisher ();
		}

		return publisher_value;
	}

	public float get_rating () {
		if (!rating_loaded) {
			on_rating_loaded ();
			rating.notify.connect (on_rating_loaded);
			return rating.get_rating ();
		}

		return rating_value;
	}

	public DateTime get_release_date () {
		if (!release_date_loaded) {
			on_release_date_loaded ();
			release_date.notify.connect (on_release_date_loaded);
			return release_date.get_release_date ();
		}

		return release_date_value;
	}

	private void on_cooperative_loaded () {
		if (!cooperative.has_loaded)
			return;

		cooperative_value = cooperative.get_cooperative ();
		cooperative_loaded = true;

		add_game ();
		save_cooperative ();
	}

	private void on_description_loaded () {
		if (!description.has_loaded)
			return;

		description_value = description.get_description ();
		description_loaded = true;

		add_game ();
		save_description ();
	}

	private void on_developer_loaded () {
		if (!developer.has_loaded)
			return;

		developer_value = developer.get_developer ();
		developer_loaded = true;

		add_game ();
		save_developer ();
	}

	private void on_genre_loaded () {
		if (!genre.has_loaded)
			return;

		genre_value = genre.get_genre ().copy ();
		genre_loaded = true;

		add_game ();
		save_genre ();
	}

	private void on_players_loaded () {
		if (!players.has_loaded)
			return;

		players_value = players.get_players ();
		players_loaded = true;

		add_game ();
		save_players ();
	}

	private void on_publisher_loaded () {
		if (!publisher.has_loaded)
			return;

		publisher_value = publisher.get_publisher ();
		publisher_loaded = true;

		add_game ();
		save_publisher ();
	}

	private void on_rating_loaded () {
		if (!rating.has_loaded)
			return;

		rating_value = rating.get_rating ();
		rating_loaded = true;

		add_game ();
		save_rating ();
	}

	private void on_release_date_loaded () {
		if (!release_date.has_loaded)
			return;

		release_date_value = release_date.get_release_date ();
		release_date_loaded = true;

		add_game ();
		save_release_date ();
	}

	private void save_cooperative () {
		try {
			save_cooperative_statement.reset ();
			Database.bind_text (save_cooperative_statement, "$UID", uid_value);
			Database.bind_int (save_cooperative_statement, "$COOPERATIVE", cooperative_value ? 1 : 0);

			if (save_cooperative_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_description () {
		try {
			save_description_statement.reset ();
			Database.bind_text (save_description_statement, "$UID", uid_value);
			Database.bind_text (save_description_statement, "$DESCRIPTION", description_value);

			if (save_description_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_developer () {
		try {
			save_developer_statement.reset ();
			Database.bind_text (save_developer_statement, "$UID", uid_value);
			Database.bind_text (save_developer_statement, "$DEVELOPER", developer_value);

			if (save_developer_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_genre () {
		try {
			var variant = new Variant.strv (genre_value);
			var string_value = variant.print (false);

			save_genre_statement.reset ();
			Database.bind_text (save_genre_statement, "$UID", uid_value);
			Database.bind_text (save_genre_statement, "$GENRE", string_value);

			if (save_genre_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_players () {
		try {
			save_players_statement.reset ();
			Database.bind_text (save_players_statement, "$UID", uid_value);
			Database.bind_text (save_players_statement, "$PLAYERS", players_value);

			if (save_players_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_publisher () {
		try {
			save_publisher_statement.reset ();
			Database.bind_text (save_publisher_statement, "$UID", uid_value);
			Database.bind_text (save_publisher_statement, "$PUBLISHER", publisher_value);

			if (save_publisher_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_rating () {
		try {
			save_rating_statement.reset ();
			Database.bind_text (save_rating_statement, "$UID", uid_value);
			Database.bind_double (save_rating_statement, "$RATING", rating_value);

			if (save_rating_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save_release_date () {
		try {
			var string_value = "";
			if (release_date_value != null)
				string_value = release_date_value.format ("%F");

			save_release_date_statement.reset ();
			Database.bind_text (save_release_date_statement, "$UID", uid_value);
			Database.bind_text (save_release_date_statement, "$RELEASE_DATE", string_value);

			if (save_release_date_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void add_game () {
		if (game_added)
			return;

		game_added = true;

		try {
			add_game_statement.reset ();

			Database.bind_text (add_game_statement, "$UID", uid_value);

			if (add_game_statement.step () != Sqlite.DONE)
				warning ("Execution failed.");
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void load_metadata () throws Error {
		load_statement.reset ();

		Database.bind_text (load_statement, "$UID", uid_value);

		if (load_statement.step () == Sqlite.ROW) {
			if (load_statement.column_type (0) != Sqlite.NULL) {
				cooperative_value = load_statement.column_int (0) == 1;
				cooperative_loaded = true;
			}

			if (load_statement.column_type (1) != Sqlite.NULL) {
				description_value = load_statement.column_text (1);
				description_loaded = true;
			}

			if (load_statement.column_type (2) != Sqlite.NULL) {
				developer_value = load_statement.column_text (2);
				developer_loaded = true;
			}

			if (load_statement.column_type (3) != Sqlite.NULL) {
				var string_value = load_statement.column_text (3);
				var variant = Variant.parse (VariantType.STRING_ARRAY, string_value);
				genre_value = variant.get_strv ();

				genre_loaded = true;
			}

			if (load_statement.column_type (4) != Sqlite.NULL) {
				players_value = load_statement.column_text (4);
				players_loaded = true;
			}

			if (load_statement.column_type (5) != Sqlite.NULL) {
				publisher_value = load_statement.column_text (5);
				publisher_loaded = true;
			}

			if (load_statement.column_type (6) != Sqlite.NULL) {
				rating_value = (float) load_statement.column_double (6);
				rating_loaded = true;
			}

			if (load_statement.column_type (7) != Sqlite.NULL) {
				var string_value = load_statement.column_text (7);

				if (string_value != "") {
					var timezone = new TimeZone.utc ();

					release_date_value = new DateTime.from_iso8601 (string_value, timezone);
				}

				release_date_loaded = true;
			}
		}
	}
}
