// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameCollection : Object {
	public signal void game_added (Game game);

	private GenericSet<Game> games;
	private UriSource[] sources;
	private UriGameFactory[] factories;
	private RunnerFactory[] runner_factories;

	private HashTable<string, Array<UriGameFactory>> factories_for_mime_type;
	private HashTable<string, Array<UriGameFactory>> factories_for_scheme;
	private HashTable<Platform, Array<RunnerFactory>> runner_factories_for_platforms;

	public bool paused { get; set; }

	construct {
		games = new GenericSet<Game> (Game.hash, Game.equal);
		factories_for_mime_type = new HashTable<string, Array<UriGameFactory>> (str_hash, str_equal);
		factories_for_scheme = new HashTable<string, Array<UriGameFactory>> (str_hash, str_equal);
		runner_factories_for_platforms = new HashTable<Platform, Array<RunnerFactory>> (Platform.hash, Platform.equal);
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
		SourceFunc callback = search_games.callback;

		ThreadFunc<void*> run = () => {
			foreach (var source in sources)
				foreach (var uri in source) {
					if (paused) {
						Idle.add ((owned) callback);
						return null;
					}

					add_uri (uri);
				}

			Idle.add ((owned) callback);
			return null;
		};

		new Thread<void*> (null, (owned) run);

		yield;
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
		if (games.contains (game))
			return;

		games.add (game);
		Idle.add (() => {
			game_added (game);
			return Source.REMOVE;
		});
	}
}
