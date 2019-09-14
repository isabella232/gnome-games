// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.TurboGrafxCDPlugin : Object, Plugin {
	private const string PHONY_MIME_TYPE = "application/x-pc-engine-cd-rom";
	private const string CUE_MIME_TYPE = "application/x-cue";
	private const string CD_MAGIC_VALUE = "PC Engine CD-ROM SYSTEM";
	private const string PLATFORM_ID = "TurboGrafxCD";
	/* translators: known as "CD-ROM²" in eastern Asia and France */
	private const string PLATFORM_NAME = _("TurboGrafx-CD");
	private const string PLATFORM_UID_PREFIX = "pc-engine";

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
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (CUE_MIME_TYPE);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		if (!is_valid_disc (uri))
			throw new TurboGrafxCDError.INVALID_DISC ("“%s” isn’t a valid TurboGrafx-CD disc.", uri.to_string ());

		var uid = new FingerprintUid (uri, PLATFORM_UID_PREFIX);
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, PHONY_MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});
		var release_date = new GriloReleaseDate (media);
		var genre = new GriloGenre (media);
		var players = new GriloPlayers (media);
		var developer = new GriloDeveloper (media);
		var rating = new GriloRating (media);
		var core_source = new RetroCoreSource (platform);

		var builder = new RetroRunnerBuilder ();
		builder.core_source = core_source;
		builder.uri = uri;
		builder.uid = uid;
		builder.title = title;
		var runner = builder.to_runner ();

		var game = new GenericGame (uid, title, platform, runner);
		game.set_cover (cover);
		game.set_release_date (release_date);
		game.set_genre (genre);
		game.set_players (players);
		game.set_developer (developer);
		game.set_rating (rating);

		return game;
	}

	private static bool is_valid_disc (Uri uri) throws Error {
		var file = uri.to_file ();
		var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
		var mime_type = file_info.get_content_type ();

		File bin_file;
		switch (mime_type) {
		case CUE_MIME_TYPE:
			var cue = new CueSheet (file);
			if (cue.tracks_number < 2)
				return false;

			var track = cue.get_track (1);
			if (!track.track_mode.is_mode1 ())
				return false;

			bin_file = track.file.file;

			break;
		// TODO Add support for binary files.
		default:
			return false;
		}

		var path = bin_file.get_path ();
		var offsets = Grep.get_offsets (path, CD_MAGIC_VALUE);

		return offsets.length > 0;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.TurboGrafxCDPlugin);
}
