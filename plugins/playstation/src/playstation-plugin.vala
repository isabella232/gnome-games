// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PlayStation : Object, Plugin {
	private const string CUE_MIME_TYPE = "application/x-cue";
	private const string PHONY_MIME_TYPE = "application/x-playstation-rom";
	private const string PLATFORM_ID = "PlayStation";
	private const string PLATFORM_NAME = _("PlayStation");
	private const string PLATFORM_UID_PREFIX = "playstation";

	private static RetroPlatform platform;

	static construct {
		string[] mime_types = { CUE_MIME_TYPE, PHONY_MIME_TYPE };
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, mime_types, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return { CUE_MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var factory = new PlayStationGameFactory (platform);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new GenericRunnerFactory (create_runner);
		factory.add_platform (platform);

		return { factory };
	}

	public static Runner? create_runner (Game game) throws Error {
		var core_source = new RetroCoreSource (platform);

		var builder = new RetroRunnerBuilder ();
		builder.core_source = core_source;
		builder.media_set = game.get_media_set ();
		builder.uid = game.get_uid ();
		builder.title = game.name;

		return builder.to_runner ();
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.PlayStation);
}
