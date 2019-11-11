// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MameGameUriAdapter : GameUriAdapter, Object {
	private RetroPlatform platform;

	public MameGameUriAdapter (RetroPlatform platform) {
		this.platform = platform;
	}

	public async Game game_for_uri (Uri uri) throws Error {
		var supported_games = yield MameGameInfo.get_supported_games ();

		var file = uri.to_file ();
		var game_id = file.get_basename ();
		game_id = /\.zip$/.replace (game_id, game_id.length, 0, "");

		if (!supported_games.contains (game_id))
			throw new MameError.INVALID_GAME_ID (_("Invalid MAME game id “%s” for “%s”."), game_id, uri.to_string ());

		var uid_string = @"mame-$game_id".down ();
		var uid = new GenericUid (uid_string);

		var info = supported_games[game_id];
		var title_string = info.name;
		title_string = title_string.split ("(")[0];
		title_string = title_string.strip ();
		var title = new GenericTitle (title_string);
		var cover = new LocalCover (uri);

		Idle.add (this.game_for_uri.callback);
		yield;

		var game = new GenericGame (uid, uri, title, platform);
		game.set_cover (cover);

		return game;
	}
}
