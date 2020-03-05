// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroSimpleGameUriAdapter : GameUriAdapter, Object {
	private RetroSimpleType simple_type;
	private RetroPlatform platform;

	public RetroSimpleGameUriAdapter (RetroSimpleType simple_type, RetroPlatform platform) {
		this.simple_type = simple_type;
		this.platform = platform;
	}

	public Game game_for_uri (Uri uri) throws Error {
		var uid = new Uid (Fingerprint.get_uid (uri, simple_type.prefix));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, simple_type.mime_type);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var game = new Game (uid, uri, title, platform);
		game.set_cover (cover);

		return game;
	}
}
