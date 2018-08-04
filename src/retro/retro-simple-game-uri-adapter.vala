// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroSimpleGameUriAdapter : GameUriAdapter, Object {
	private RetroSimpleType simple_type;

	public RetroSimpleGameUriAdapter (RetroSimpleType simple_type) {
		this.simple_type = simple_type;
	}

	public async Game game_for_uri (Uri uri) throws Error {
		Idle.add (this.game_for_uri.callback);
		yield;

		var uid = new FingerprintUid (uri, simple_type.prefix);
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, simple_type.mime_type);
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
		var platform_name = simple_type.get_platform_name ();
		var platform = new GenericPlatform (simple_type.platform, platform_name);
		var core_source = new RetroCoreSource (platform, { simple_type.mime_type });
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
}
