// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MsDosPlugin : Object, Plugin {
	private const string FINGERPRINT_PREFIX = "ms-dos";
	private const string MIME_TYPE = "application/x-ms-dos-executable";
	private const string PLATFORM_ID = "MSDOS";
	private const string PLATFORM_NAME = _("MS-DOS");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);
	}

	public UriGameFactory[] get_uri_game_factories () {
		var game_uri_adapter = new GenericGameUriAdapter (game_for_uri);
		var factory = new GenericUriGameFactory (game_uri_adapter);
		factory.add_mime_type (MIME_TYPE);

		return { factory };
	}

	private static Game game_for_uri (Uri uri) throws Error {
		var uid = new FingerprintUid (uri, FINGERPRINT_PREFIX);
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, MIME_TYPE);
		var release_date = new GriloReleaseDate (media);
		var cooperative = new GriloCooperative (media);
		var genre = new GriloGenre (media);
		var players = new GriloPlayers (media);
		var developer = new GriloDeveloper (media);
		var publisher = new GriloPublisher (media);
		var description = new GriloDescription (media);
		var rating = new GriloRating (media);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var core_source = new RetroCoreSource (platform, { MIME_TYPE });
		var input_capabilities = new MsDosInputCapabilities();

		var builder = new RetroRunnerBuilder ();
		builder.core_source = core_source;
		builder.uri = uri;
		builder.uid = uid;
		builder.title = title;
		builder.input_capabilities = input_capabilities;
		var runner = builder.to_runner ();

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
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof (Games.MsDosPlugin);
}
