// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.LovePlugin : Object, Plugin {
	private const string MIME_TYPE = "application/x-love-game";
	private const string PLATFORM_ID = "LOVE";
	private const string PLATFORM_NAME = _("LÖVE");
	private const string PLATFORM_UID_PREFIX = "love";

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME, PLATFORM_UID_PREFIX);
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
		var uid = new GenericUid (Fingerprint.get_uid (uri, PLATFORM_UID_PREFIX));
		var package = new LovePackage (uri);
		var title = new LoveTitle (package);
		var icon = new LoveIcon (package);
		var cover = new LocalCover (uri);

		var game = new Game (uid, uri, title, platform);
		game.set_icon (icon);
		game.set_cover (cover);

		return game;
	}

	private static Runner? create_runner (Game game) throws Error {
		var uri = game.get_uri ();
		string[] args = { "love", uri.to_string () };
		return new CommandRunner (args);
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.LovePlugin);
}
