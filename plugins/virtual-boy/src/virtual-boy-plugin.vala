// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.VirtualBoyPlugin : Object, Plugin {
	private const string MIME_TYPE = "application/x-virtual-boy-rom";
	private const string PLATFORM_ID = "VirtualBoy";
	private const string PLATFORM_NAME = _("Virtual Boy");
	private const string PLATFORM_UID_PREFIX = "virtual-boy";

	private static RetroPlatform platform;

	static construct {
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, { MIME_TYPE }, PLATFORM_UID_PREFIX);
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
		var factory = new RetroRunnerFactory (platform);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var file = uri.to_file ();

		var header = new VirtualBoyHeader (file);
		header.check_validity ();

		var uid = new GenericUid (Fingerprint.get_uid (uri, PLATFORM_UID_PREFIX));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, MIME_TYPE);
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
	return typeof (Games.VirtualBoyPlugin);
}
