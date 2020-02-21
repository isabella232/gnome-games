// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamPlugin : Object, Plugin {
	private const string STEAM_APPID = "com.valvesoftware.Steam";
	private const string STEAM_FLATPAK_DIR = "/.var/app/" + STEAM_APPID;

	private const string STEAM_SCHEME = "steam";
	private const string FLATPAK_STEAM_SCHEME = "flatpak+steam";
	private const string PLATFORM_ID = "Steam";
	private const string PLATFORM_NAME = _("Steam");
	private const string PLATFORM_UID_PREFIX = "steam";

	private static Platform platform;
	private static SteamGameData game_data;
	private static SteamGameData flatpak_game_data;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME, PLATFORM_UID_PREFIX);
		game_data = new SteamGameData ();
		flatpak_game_data = new SteamGameData ();

		// Add directories where Steam installs icons
		var home = Environment.get_home_dir ();
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.append_search_path (home + "/.local/share/icons");
		icon_theme.append_search_path (home + STEAM_FLATPAK_DIR + "/.local/share/icons");
		icon_theme.append_search_path (home + STEAM_FLATPAK_DIR + "/data/icons");
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public UriSource[] get_uri_sources () {
		// Steam's installation path can be found in its registry.
		var home = Environment.get_home_dir ();

		UriSource[] sources = {};

		try {
			sources += new SteamUriSource (home, STEAM_SCHEME, game_data);
		}
		catch (Error e) {
			debug (e.message);
		}

		try {
			sources += new SteamUriSource (home + STEAM_FLATPAK_DIR, FLATPAK_STEAM_SCHEME, flatpak_game_data);
		}
		catch (Error e) {
			debug (e.message);
		}

		return sources;
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_steam_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_scheme (STEAM_SCHEME);

		var game_uri_adapter_flatpak = new GenericGameUriAdapter (game_for_flatpak_steam_uri);
		var factory_flatpak = new GenericUriGameFactory (game_uri_adapter_flatpak);
		factory_flatpak.add_scheme (FLATPAK_STEAM_SCHEME);

		return { factory, factory_flatpak };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new GenericRunnerFactory (create_runner);
		factory.add_platform (platform);

		return { factory };
	}

	private static Game game_for_steam_uri (Uri uri) throws Error {
		return create_game (uri, "steam", "");
	}

	private static Game game_for_flatpak_steam_uri (Uri uri) throws Error {
		return create_game (uri, STEAM_APPID, "flatpak");
	}

	private static Game create_game (Uri uri, string app_id, string prefix) throws Error {
		var scheme = uri.get_scheme ();

		var uri_string = uri.to_string ();
		var pos = uri_string.last_index_of ("/");
		var game_id = uri_string.substring (pos + 1);

		string game_title;
		switch (scheme) {
		case STEAM_SCHEME:
			game_title = game_data.get_title (game_id);
			break;

		case FLATPAK_STEAM_SCHEME:
			game_title = flatpak_game_data.get_title (game_id);
			break;

		default:
			assert_not_reached ();
		}

		var uid = new GenericUid (@"$PLATFORM_UID_PREFIX-$prefix$game_id".down ());
		var title = new GenericTitle (game_title);
		var icon = new SteamIcon (app_id, game_id);
		var cover = new SteamCover (game_id);

		var game = new Game (uid, uri, title, platform);
		game.set_icon (icon);
		game.set_cover (cover);

		return game;
	}

	private static Runner? create_runner (Game game) throws Error {
		var uri = game.get_uri ();
		var scheme = uri.get_scheme ();
		var steam_uri = new Uri.from_uri_and_scheme (uri, STEAM_SCHEME);

		string[] command;
		switch (scheme) {
		case STEAM_SCHEME:
			command = { "steam" };
			break;

		case FLATPAK_STEAM_SCHEME:
			command = { "flatpak", "run", STEAM_APPID };
			break;

		default:
			assert_not_reached ();
		}

		command += steam_uri.to_string ();
		return new CommandRunner (command);
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.SteamPlugin);
}
