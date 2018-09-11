// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamPlugin : Object, Plugin {
	private const string STEAM_APPID = "com.valvesoftware.Steam";
	private const string STEAM_FLATPAK_DIR = "/.var/app/" + STEAM_APPID;

	private const string STEAM_FILE_SCHEME = "steam+file";
	private const string FLATPAK_STEAM_FILE_SCHEME = "flatpak+steam+file";
	private const string PLATFORM_ID = "Steam";
	private const string PLATFORM_NAME = _("Steam");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);

		// Add directories where Steam installs icons
		var home = Environment.get_home_dir ();
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.append_search_path (home + "/.local/share/icons");
		icon_theme.append_search_path (home + STEAM_FLATPAK_DIR + "/.local/share/icons");
		icon_theme.append_search_path (home + STEAM_FLATPAK_DIR + "/data/icons");
	}

	public UriSource[] get_uri_sources () {
		// Steam's installation path can be found in its registry.
		var home = Environment.get_home_dir ();

		UriSource[] sources = {};

		try {
			sources += new SteamUriSource (home, STEAM_FILE_SCHEME);
		}
		catch (Error e) {
			debug (e.message);
		}

		try {
			sources += new SteamUriSource (home + STEAM_FLATPAK_DIR, FLATPAK_STEAM_FILE_SCHEME);
		}
		catch (Error e) {
			debug (e.message);
		}

		return sources;
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_steam_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_scheme (STEAM_FILE_SCHEME);

		var game_uri_adapter_flatpak = new GenericGameUriAdapter (game_for_flatpak_steam_uri);
		var factory_flatpak = new GenericUriGameFactory (game_uri_adapter_flatpak);
		factory_flatpak.add_scheme (FLATPAK_STEAM_FILE_SCHEME);

		return { factory, factory_flatpak };
	}

	private static Game game_for_steam_uri (Uri uri) throws Error {
		return create_game (uri, "steam", "", { "steam" });
	}

	private static Game game_for_flatpak_steam_uri (Uri uri) throws Error {
		return create_game (uri, STEAM_APPID, "flatpak", { "flatpak", "run", STEAM_APPID });
	}

	private static Game create_game (Uri uri, string app_id, string prefix, string[] command) throws Error {
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

		var uid = new SteamUid (prefix, game_id);
		var title = new SteamTitle (registry);
		var icon = new SteamIcon (app_id, game_id);
		var cover = new SteamCover (game_id);

		string[] args = {};
		foreach (var part in command)
			args += part;
		args += @"steam://rungameid/$game_id";
		var runner = new CommandRunner (args);

		var game = new GenericGame (uid, title, platform, runner);
		game.set_icon (icon);
		game.set_cover (cover);

		return game;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.SteamPlugin);
}
