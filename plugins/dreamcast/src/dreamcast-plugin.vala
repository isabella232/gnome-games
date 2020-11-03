// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DreamcastPlugin : Object, Plugin {
	private const string GDI_MIME_TYPE = "application/x-gd-rom-cue";
	private const string CDI_MIME_TYPE = "application/x-discjuggler-cd-image";
	private const string DREAMCAST_MIME_TYPE = "application/x-dreamcast-rom";
	private const string PLATFORM_ID = "Dreamcast";
	private const string PLATFORM_NAME = _("Dreamcast");
	private const string PLATFORM_UID_PREFIX = "dreamcast";
	private const string[] MIME_TYPES = { GDI_MIME_TYPE, CDI_MIME_TYPE };

	private static RetroPlatform platform;

	static construct {
		platform = new RetroPlatform (PLATFORM_ID, PLATFORM_NAME, MIME_TYPES, PLATFORM_UID_PREFIX);
	}

	public Platform[] get_platforms () {
		return { platform };
	}

	public string[] get_mime_types () {
		return MIME_TYPES;
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		foreach (var mime_type in MIME_TYPES)
			factory.add_mime_type (mime_type);

		return { factory };
	}

	public RunnerFactory[] get_runner_factories () {
		var factory = new RetroRunnerFactory (platform);

		return { factory };
	}

	private static string get_uid (DreamcastHeader header) throws Error {
		var product_number = header.get_product_number ();
		var areas = header.get_areas ();

		return @"$PLATFORM_UID_PREFIX-$product_number-$areas".down ();
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var file = uri.to_file ();
		var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
		var mime_type = file_info.get_content_type ();

		File bin_file;
		switch (mime_type) {
		case GDI_MIME_TYPE:
			var gdi = new Gdi (file);
			gdi.parse ();
			bin_file = get_binary_file (gdi);

			break;
		case CDI_MIME_TYPE:
			bin_file = file;

			break;
		default:
			throw new DreamcastError.INVALID_FILE_TYPE ("Invalid file type: expected %s or %s but got %s for file %s.", GDI_MIME_TYPE, CDI_MIME_TYPE, mime_type, uri.to_string ());
		}

		var header = new DreamcastHeader (bin_file);
		header.check_validity ();

		var uid = new Uid (get_uid (header));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, DREAMCAST_MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var game = new Game (uid, uri, title, platform);
		game.set_cover (cover);

		return game;
	}

	private static File get_binary_file (Gdi gdi) throws Error {
		if (gdi.tracks_number == 0)
			throw new DreamcastError.INVALID_GDI ("The file “%s” doesn’t have a track.", gdi.file.get_uri ());

		var track = gdi.get_track (0);
		var file = track.file;

		var file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
		if (file_info.get_content_type () != DREAMCAST_MIME_TYPE)
			throw new DreamcastError.INVALID_FILE_TYPE ("The file “%s” doesn’t have a valid Dreamcast binary file.", gdi.file.get_uri ());

		return file;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.DreamcastPlugin);
}
