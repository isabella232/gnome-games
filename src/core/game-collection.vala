// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameCollection : Object {
	public signal void game_added (Game game);
	public signal void game_replaced (Game game, Game prev_game);
	public signal void game_removed (Game game);

	private signal void loading_done ();

	private HashTable<string, Game> games;
	private HashTable<string, Game> cached_games;
	private UriSource[] sources;
	private UriGameFactory[] factories;
	private RunnerFactory[] runner_factories;
	private Database database;

	private HashTable<string, Array<UriGameFactory>> factories_for_mime_type;
	private HashTable<string, Array<UriGameFactory>> factories_for_scheme;
	private HashTable<Platform, Array<RunnerFactory>> runner_factories_for_platforms;

	private SourceFunc search_games_cb;
	private bool is_preloading_done;
	private bool is_loading_done;

	public bool paused { get; set; }

	public GameCollection (Database database) {
		this.database = database;

		games = new HashTable<string, Game> (str_hash, str_equal);
		cached_games = new HashTable<string, Game> (str_hash, str_equal);
		factories_for_mime_type = new HashTable<string, Array<UriGameFactory>> (str_hash, str_equal);
		factories_for_scheme = new HashTable<string, Array<UriGameFactory>> (str_hash, str_equal);
		runner_factories_for_platforms = new HashTable<Platform, Array<RunnerFactory>> (Platform.hash, Platform.equal);

		add_source (database.get_uri_source ());
	}

	public void add_source (UriSource source) {
		sources += source;
	}

	public void add_factory (UriGameFactory factory) {
		factories += factory;

		foreach (var mime_type in factory.get_mime_types ()) {
			if (!factories_for_mime_type.contains (mime_type))
				factories_for_mime_type[mime_type] = new Array<UriGameFactory> ();
			factories_for_mime_type[mime_type].append_val (factory);
		}

		foreach (var scheme in factory.get_schemes ()) {
			if (!factories_for_scheme.contains (scheme))
				factories_for_scheme[scheme] = new Array<UriGameFactory> ();
			factories_for_scheme[scheme].append_val (factory);
		}

		factory.set_game_added_callback (store_game);
	}

	public void add_runner_factory (RunnerFactory factory) {
		runner_factories += factory;

		foreach (var platform in factory.get_platforms ()) {
			if (!runner_factories_for_platforms.contains (platform))
				runner_factories_for_platforms[platform] = new Array<RunnerFactory> ();
			runner_factories_for_platforms[platform].append_val (factory);
		}
	}

	public string[] get_accepted_mime_types () {
		return factories_for_mime_type.get_keys_as_array ();
	}

	public void add_uri (Uri uri) {
		foreach (var factory in get_factories_for_uri (uri))
			factory.add_uri (uri);
	}

	public Game? query_game_for_uri (Uri uri) {
		Game[] games = {};
		foreach (var factory in get_factories_for_uri (uri)) {
			var game = factory.query_game_for_uri (uri);
			if (game != null)
				games += game;
		}

		if (games.length != 1)
			return null;

		return games[0];
	}

	public async void search_games () {
		if (search_games_cb != null)
			return;

		search_games_cb = search_games.callback;

		ThreadFunc<void*> run = () => {
			if (!is_preloading_done) {
				try {
					database.list_cached_games ((game) => {
						cached_games[game.get_uri ().to_string ()] = game;

						var uid = game.uid.get_uid ();

						if (games.contains (uid))
							return;

						games[uid] = game;

						Idle.add (() => {
							game_added (game);
							return Source.REMOVE;
						});
					});
				}
				catch (Error e) {
					critical ("Couldn't load cached games: %s", e.message);
				}

				is_preloading_done = true;

				if (paused) {
					Idle.add ((owned) search_games_cb);
					return null;
				}
			}

			foreach (var source in sources)
				foreach (var uri in source) {
					if (paused) {
						Idle.add ((owned) search_games_cb);
						return null;
					}
					add_uri (uri);
				}

			cached_games.foreach_steal ((uri, game) => {
				var removed = false;
				try {
					removed = database.remove_game (uri, game);
				}
				catch (Error e) {
					warning ("Couldn't remove game: %s", e.message);
				}

				var uid = game.uid.get_uid ();

				games.remove (uid);
				if (removed)
					Idle.add (() => {
						game_removed (game);
						return Source.REMOVE;
					});

				return true;
			});

			Idle.add ((owned) search_games_cb);
			return null;
		};

		new Thread<void*> (null, (owned) run);

		yield;

		is_loading_done = true;
		loading_done ();

		search_games_cb = null;
	}

	public Runner? create_runner (Game game) {
		var platform = game.get_platform ();

		if (!runner_factories_for_platforms.contains (platform))
			return null;

		var factories = runner_factories_for_platforms[platform];
		if (factories == null)
			return null;

		foreach (var factory in factories.data) {
			try {
				var runner = factory.create_runner (game);
				if (runner != null)
					return runner;
			}
			catch (Error e) {
				critical ("Couldn't create runner: %s", e.message);
			}
		}

		return null;
	}

	private UriGameFactory[] get_factories_for_uri (Uri uri) {
		UriGameFactory[] factories = {};

		string scheme;
		try {
			scheme = uri.get_scheme ();
		}
		catch (Error e) {
			debug (e.message);

			return factories;
		}

		if (scheme == "file") {
			try {
				var file = uri.to_file ();
				foreach (var factory in get_factories_for_file (file))
					factories += factory;
			}
			catch (Error e) {
				debug (e.message);
			}
		}
		// TODO Add support for URN.
		if (factories_for_scheme.contains (scheme))
			foreach (var factory in factories_for_scheme[scheme].data)
				factories += factory;

		return factories;
	}

	private UriGameFactory[] get_factories_for_file (File file) throws Error {
		if (!file.query_exists ())
			return {};

		var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
		var mime_type = file_info.get_content_type ();
		if (!factories_for_mime_type.contains (mime_type))
			return {};

		return factories_for_mime_type[mime_type].data;
	}

	private void store_game (Game game) {
		var uri = game.get_uri ().to_string ();
		if (cached_games.contains (uri)) {
			var cached_game = cached_games.take (uri);

			try {
				database.update_game (game, cached_game);
			}
			catch (Error e) {
				warning ("Couldn't update game: %s", e.message);
			}

			Idle.add (() => {
				game_replaced (game, cached_game);
				return Source.REMOVE;
			});

			return;
		}

		Game? prev_game = null;
		try {
			prev_game = database.store_game (game);
		}
		catch (Error e) {
			warning ("Couldn't cache game: %s", e.message);
		}

		var uid = game.uid.get_uid ();

		if (games.contains (uid) && prev_game == null)
			return;

		games[uid] = game;

		Idle.add (() => {
			if (prev_game != null)
				game_replaced (game, prev_game);
			else
				game_added (game);
			return Source.REMOVE;
		});
	}

	public async Game? query_game_for_uid (string uid) {
		if (uid in games)
			return games[uid];

		if (is_loading_done)
			return null;

		Game? result = null;
		ulong game_added_id = 0;
		ulong loading_done_id = 0;

		game_added_id = game_added.connect ((game) => {
			var game_uid = game.uid.get_uid ();

			if (game_uid != uid)
				return;

			result = game;
			disconnect (game_added_id);
			disconnect (loading_done_id);
			query_game_for_uid.callback ();
		});

		loading_done_id = loading_done.connect (() => {
			disconnect (game_added_id);
			disconnect (loading_done_id);
			query_game_for_uid.callback ();
		});

		yield;

		return result;
	}
}
