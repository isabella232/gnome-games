// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SharpX68000Plugin : Object, Plugin {
	private const string MIME_TYPE_DIM = "application/x-x68k-rom";
	private const string MIME_TYPE_XDF = "application/x-x68k-xdf-rom";
	private const string MIME_TYPE_HDF = "application/x-x68k-hdf-rom";
	private const string PLATFORM_ID = "SharpX68000";
	private const string PLATFORM_NAME = _("Sharp X68000");
	private const string PLATFORM_UID_PREFIX = "sharp-x68000";

	private static RetroPlatform platform;

	static construct {
		string[] mime_types = { MIME_TYPE_DIM, MIME_TYPE_XDF, MIME_TYPE_HDF };
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, mime_types, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return { MIME_TYPE_DIM, MIME_TYPE_XDF, MIME_TYPE_HDF };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var factory = new SharpX68000GameFactory (platform);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new GenericRunnerFactory (create_runner);
		factory.add_platform (platform);

		return { factory };
	}

	private static Runner? create_runner (Game game) throws Error {
		var core_source = new RetroCoreSource (platform);
		var runner = new RetroRunner.from_source (game, core_source);

		runner.input_capabilities = new GenericInputCapabilities (true, true);

		return runner;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof(Games.SharpX68000Plugin);
}
