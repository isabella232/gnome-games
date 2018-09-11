// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MamePlugin : Object, Plugin {
	private const string MIME_TYPE = "application/zip";
	private const string PLATFORM_ID = "MAME";
	private const string PLATFORM_NAME = _("Arcade");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);
	}

	public string[] get_mime_types () {
		return { MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new MameGameUriAdapter (platform);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (MIME_TYPE);

		return { factory };
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.MamePlugin);
}
