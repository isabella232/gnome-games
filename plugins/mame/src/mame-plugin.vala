// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MamePlugin : Object, Plugin {
	private const string SEARCHED_MIME_TYPE = "application/zip";
	private const string SPECIFIC_MIME_TYPE = "application/x-mame-rom";
	private const string PLATFORM_ID = "MAME";
	private const string PLATFORM_NAME = _("Arcade");
	private const string PLATFORM_UID_PREFIX = "mame";

	private static RetroPlatform platform;

	static construct {
		string[] mime_types = { SEARCHED_MIME_TYPE, SPECIFIC_MIME_TYPE };
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, mime_types, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return { SEARCHED_MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new MameGameUriAdapter (platform);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (SEARCHED_MIME_TYPE);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new RetroRunnerFactory (platform);

		return { factory };
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.MamePlugin);
}
