// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamPlugin : Object, Plugin {
	private const string STEAM_FILE_SCHEME = "steam+file";
	private const string PLATFORM_ID = "Steam";
	private const string PLATFORM_NAME = _("Steam");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);
	}

	public UriSource[] get_uri_sources () {
		try {
			var source = new SteamUriSource ();

			return { source };
		}
		catch (Error e) {
			debug (e.message);
		}

		return {};
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_scheme (STEAM_FILE_SCHEME);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var file_uri = new Uri.from_uri_and_scheme (uri, "file");
		var file = file_uri.to_file ();
		var appmanifest_path = file.get_path ();
		var registry = new SteamRegistry (appmanifest_path);
		var game_id = registry.get_data ({"AppState", "appid"});
		/* The gamegames_id sometimes is identified by appID
		 * see issue https://github.com/Kekun/gnome-games/issues/169 */
		if (game_id == null)
			game_id = registry.get_data ({"AppState", "appID"});

		if (game_id == null)
			throw new SteamError.NO_APPID (_("Couldn’t get Steam appid from manifest “%s”."), appmanifest_path);

		var uid = new SteamUid (game_id);
		var title = new SteamTitle (registry);
		var icon = new SteamIcon (game_id);
		var cover = new SteamCover (game_id);
		string[] args = { "steam", @"steam://rungameid/" + game_id };
		var runner = new CommandRunner (args, false);

		var game = new GenericGame (uid, title, platform, runner);
		game.set_icon (icon);
		game.set_cover (cover);

		return game;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof(Games.SteamPlugin);
}
