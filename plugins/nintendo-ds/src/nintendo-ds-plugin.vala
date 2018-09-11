// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.NintendoDsPlugin : Object, Plugin {
	private const string FINGERPRINT_PREFIX = "nintendo-ds";
	private const string MIME_TYPE = "application/x-nintendo-ds-rom";
	private const string PLATFORM_ID = "NintendoDS";
	private const string PLATFORM_NAME = _("Nintendo DS");

	private static Platform platform;

	static construct {
		platform = new GenericPlatform (PLATFORM_ID, PLATFORM_NAME);
	}

	public string[] get_mime_types () {
		return { MIME_TYPE };
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
		var icon = new NintendoDsIcon (uri);
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
		var runner = new RetroRunner (core_source, uri, uid, title);

		var game = new GenericGame (uid, title, platform, runner);
		game.set_icon (icon);
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
	return typeof (Games.NintendoDsPlugin);
}
