// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SegaCDPlugin : Object, Plugin {
	private const string 32X_MIME_TYPE = "application/x-genesis-32x-rom";

	private const string SEGA_CD_PREFIX = "mega-cd";
	private const string CUE_MIME_TYPE = "application/x-cue";
	private const string SEGA_CD_MIME_TYPE = "application/x-sega-cd-rom";
	private const string SEGA_CD_PLATFORM = "SegaCD";
	private const string SEGA_CD_32X_PLATFORM = "SegaCD32X";
	private const string SEGA_CD_PLATFORM_NAME = _("Sega CD");
	private const string SEGA_CD_32X_PLATFORM_NAME = _("Sega CD 32X");

	public string[] get_mime_types () {
		return { CUE_MIME_TYPE, SEGA_CD_MIME_TYPE };
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (CUE_MIME_TYPE);
		factory.add_mime_type (SEGA_CD_MIME_TYPE);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var file = uri.to_file ();
		var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
		var mime_type = file_info.get_content_type ();

		File bin_file;
		switch (mime_type) {
		case CUE_MIME_TYPE:
			var cue = new CueSheet (file);
			bin_file = get_binary_file (cue);

			break;
		case SEGA_CD_MIME_TYPE:
			bin_file = file;

			break;
		default:
			throw new SegaCDError.INVALID_FILE_TYPE ("Invalid file type: expected %s or %s but got %s for file %s.", CUE_MIME_TYPE, SEGA_CD_MIME_TYPE, mime_type, uri.to_string ());
		}

		var header = new SegaCDHeader (bin_file);
		header.check_validity ();

		string[] mime_types;
		string generic_platform;
		string platform_name;
		if (header.is_sega_cd ()) {
			mime_types = { CUE_MIME_TYPE, SEGA_CD_MIME_TYPE };
			generic_platform = SEGA_CD_PLATFORM;
			platform_name = SEGA_CD_PLATFORM_NAME;
		}
		else if (header.is_sega_cd_32x ()) {
			mime_types = { CUE_MIME_TYPE, SEGA_CD_MIME_TYPE, 32X_MIME_TYPE };
			generic_platform = SEGA_CD_32X_PLATFORM;
			platform_name = SEGA_CD_32X_PLATFORM_NAME;
		}
		else
			assert_not_reached ();

		var bin_uri = new Uri (bin_file.get_uri ());
		var header_offset = header.get_offset ();
		var uid = new FingerprintUid.for_chunk (bin_uri, SEGA_CD_PREFIX, header_offset, SegaCDHeader.HEADER_LENGTH);
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, SEGA_CD_MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});
		var release_date = new GriloReleaseDate (media, uid);
		var cooperative = new GriloCooperative (media, uid);
		var genre = new GriloGenre (media, uid);
		var players = new GriloPlayers (media, uid);
		var developer = new GriloDeveloper (media);
		var publisher = new GriloPublisher (media);
		var description = new GriloDescription (media);
		var rating = new GriloRating (media);
		var platform = new GenericPlatform (platform_name);
		var core_source = new RetroCoreSource (generic_platform, mime_types);
		var runner = new RetroRunner (core_source, uri, uid, title);

		var game = new GenericGame (uid, title, platform, runner);
		game.set_cover (cover);
		game.set_release_date (release_date);
		game.set_cooperative (cooperative);
		game.set_genre (genre);
		game.set_players (players);
		game.set_developer (developer);
		game.set_publisher (publisher);
		game.set_description (description);
		game.set_rating (rating);

		return game;
	}

	private static File get_binary_file (CueSheet cue) throws Error {
		if (cue.tracks_number == 0)
			throw new SegaCDError.INVALID_CUE_SHEET (_("The file “%s” doesn’t have a track."), cue.file.get_uri ());

		var track = cue.get_track (0);
		var file = track.file;

		if (file.file_format != CueSheetFileFormat.BINARY && file.file_format != CueSheetFileFormat.UNKNOWN)
			throw new SegaCDError.INVALID_CUE_SHEET (_("The file “%s” doesn’t have a valid binary file format."), cue.file.get_uri ());

		if (!track.track_mode.is_mode1 ())
			throw new SegaCDError.INVALID_CUE_SHEET (_("The file “%s” doesn’t have a valid track mode for track %d."), cue.file.get_uri (), track.track_number);

		var header = new SegaCDHeader (file.file);
		header.check_validity ();

		return file.file;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof(Games.SegaCDPlugin);
}
