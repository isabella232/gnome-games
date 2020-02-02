// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.Nintendo64Plugin : Object, Plugin {
	private const string MIME_TYPE = "application/x-n64-rom";
	private const string PLATFORM_ID = "Nintendo64";
	private const string PLATFORM_NAME = _("Nintendo 64");
	private const string PLATFORM_UID_PREFIX = "nintendo-64";

	private static RetroPlatform platform;

	static construct {
		platform = new Nintendo64Platform (PLATFORM_ID, PLATFORM_NAME, { MIME_TYPE }, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return { MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (MIME_TYPE);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new GenericRunnerFactory (create_runner);
		factory.add_platform (platform);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {

		var uid = new Uid (Fingerprint.get_uid (uri, PLATFORM_UID_PREFIX));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var game = new Game (uid, uri, title, platform);
		game.set_cover (cover);

		return game;
	}

	private static Runner? create_runner (Game game) throws Error {
		var core_source = new RetroCoreSource (platform);

		return new Nintendo64Runner (game, core_source);
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.Nintendo64Plugin);
}
