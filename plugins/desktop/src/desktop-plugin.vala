// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DesktopPlugin : Object, Plugin {
	private const string DESKTOP_URI_PREFIX = "desktop+";
	private const string DESKTOP_FILE_URI_SCHEME = "desktop+file";

	private const string PLATFORM_ID = "Desktop";
	private const string PLATFORM_NAME = _("Desktop");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);

		var home = Environment.get_home_dir ();
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.prepend_search_path (home + "/.local/share/flatpak/exports/share/icons");
		icon_theme.prepend_search_path ("/var/lib/flatpak/exports/share/icons");
	}

	public UriSource[] get_uri_sources () {
		var query = new DesktopTrackerUriQuery ();
		try {
			var connection = Tracker.Sparql.Connection.@get ();
			var uri_source = new TrackerUriSource (connection);
			uri_source.add_query (query);
			uri_source.set_prefix (DESKTOP_URI_PREFIX);

			return { uri_source };
		}
		catch (Error e) {
			debug (e.message);

			return {};
		}
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_scheme (DESKTOP_FILE_URI_SCHEME);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var file_uri = new Uri.from_uri_and_scheme (uri, "file");

		var info = new DesktopTrackerAppInfo (file_uri);

		var filename = info.get_filename ();
		var command = info.get_command ();

//		check_displayability (app_info);
		check_categories (file_uri, info.get_categories ());
		check_executable (file_uri, info.get_executable ());
		check_base_name (file_uri, filename);

		var uid = new DesktopUid (filename);
		var title = new GenericTitle (info.get_title ());
		var icon = new DesktopIcon (info.get_icon ());

		string[] args;
		if (!Shell.parse_argv (command, out args))
			throw new CommandError.INVALID_COMMAND (_("Invalid command “%s”."), command);
		var runner = new CommandRunner (args);

		var game = new GenericGame (uid, title, platform, runner);
		game.set_icon (icon);

		return game;
	}
/*
	private static void check_displayability (DesktopAppInfo app_info) throws Error {
		if (app_info.get_nodisplay ())
			throw new DesktopError.BLACKLISTED_GAME (_("“%s” shouldn’t be displayed."), app_info.filename);

		if (app_info.get_is_hidden ())
			throw new DesktopError.BLACKLISTED_GAME (_("“%s” is hidden."), app_info.filename);
	}
*/
	private static void check_categories (Uri uri, string[] categories) throws Error {
		foreach (var category in get_categories_black_list ())
			if (category in categories)
				throw new DesktopError.BLACKLISTED_GAME (_("“%s” has blacklisted category “%s”."), uri.to_string (), category);
	}

	private static void check_executable (Uri uri, string app_executable) throws Error {
		foreach (var executable in get_executable_black_list ())
			if (app_executable == executable ||
			    app_executable.has_suffix ("/" + executable))
				throw new DesktopError.BLACKLISTED_GAME (_("“%s” has blacklisted executable “%s”."), uri.to_string (), executable);
	}

	private static void check_base_name (Uri uri, string base_name) throws Error {
		if (base_name in get_base_name_black_list ())
			throw new DesktopError.BLACKLISTED_GAME (_("“%s” is blacklisted."), uri.to_string ());
	}

	private static string[] categories_black_list;
	private static string[] get_categories_black_list () throws Error {
		if (categories_black_list == null)
			categories_black_list = get_lines_from_resource ("plugins/desktop/blacklists/desktop-categories.blacklist");

		return categories_black_list;
	}

	private static string[] executable_black_list;
	private static string[] get_executable_black_list () throws Error {
		if (executable_black_list == null)
			executable_black_list = get_lines_from_resource ("plugins/desktop/blacklists/desktop-executable.blacklist");

		return executable_black_list;
	}

	private static string[] base_name_black_list;
	private static string[] get_base_name_black_list () throws Error {
		if (base_name_black_list == null)
			base_name_black_list = get_lines_from_resource ("plugins/desktop/blacklists/desktop-base-name.blacklist");

		return base_name_black_list;
	}

	private static string[] get_lines_from_resource (string resource) throws Error {
		var bytes = resources_lookup_data ("/org/gnome/Games/" + resource, ResourceLookupFlags.NONE);
		var text = (string) bytes.get_data ();

		string[] lines = {};

		foreach (var line in text.split ("\n"))
			if (line != "")
				lines += line;

		return lines;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.DesktopPlugin);
}
