// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.Nintendo3DsPlugin : Object, Plugin {
	private const string 3DS_MIME_TYPE = "application/x-nintendo-3ds-rom";
	private const string 3DSX_MIME_TYPE = "application/x-nintendo-3ds-executable";
	private const string PLATFORM_ID = "Nintendo3DS";
	private const string PLATFORM_NAME = _("Nintendo 3DS");
	private const string PLATFORM_UID_PREFIX = "nintendo-3ds";
	private const string[] MIME_TYPES = { 3DS_MIME_TYPE, 3DSX_MIME_TYPE };

	private static RetroPlatform platform;

	static construct {
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, MIME_TYPES, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return MIME_TYPES;
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		foreach (var mime_type in MIME_TYPES)
			factory.add_mime_type (mime_type);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new RetroRunnerFactory (platform);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var uid = new Uid (Fingerprint.get_uid (uri, PLATFORM_UID_PREFIX));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, 3DS_MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var game = new Game (uid, uri, title, platform);
		game.set_cover (cover);

		return game;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.Nintendo3DsPlugin);
}
