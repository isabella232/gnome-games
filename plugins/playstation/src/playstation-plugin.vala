// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PlayStation : Object, Plugin {
	private const string MIME_TYPE = "application/x-cue";
	private const string PLATFORM_ID = "PlayStation";
	private const string PLATFORM_NAME = _("PlayStation");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);
	}

	public string[] get_mime_types () {
		return { MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var factory = new PlayStationGameFactory (platform);

		return { factory };
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.PlayStation);
}
