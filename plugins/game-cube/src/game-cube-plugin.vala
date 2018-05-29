// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameCubePlugin : Object, Plugin {
	private const string MIME_TYPE = "application/x-gamecube-rom";
	private const string PLATFORM = "GameCube";

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
		var file = uri.to_file ();
		var header = new GameCubeHeader (file);
		header.check_validity ();

		var uid = new GameCubeUid (header);
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, MIME_TYPE);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});
		var release_date = new GriloReleaseDate (media, uid);
		var cooperative = new GriloCooperative (media, uid);
		var genre = new GriloGenre (media, uid);
		var players = new GriloPlayers (media, uid);
		var developer = new GriloDeveloper (media);
		var publisher = new GriloPublisher (media);
		var core_source = new RetroCoreSource (PLATFORM, { MIME_TYPE });
		var runner = new RetroRunner (core_source, uri, uid, title);

		var game = new GenericGame (uid, title, runner);
		game.set_cover (cover);
		game.set_release_date (release_date);
		game.set_cooperative (cooperative);
		game.set_genre (genre);
		game.set_players (players);
		game.set_developer (developer);
		game.set_publisher (publisher);

		return game;
	}
}

[ModuleInit]
public Type register_games_plugin (TypeModule module) {
	return typeof(Games.GameCubePlugin);
}
