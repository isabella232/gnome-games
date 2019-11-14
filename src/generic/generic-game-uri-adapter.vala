// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericGameUriAdapter : GameUriAdapter, Object {
	public delegate Game GameForUri (Uri uri) throws Error;

	private GameForUri callback;

	public GenericGameUriAdapter (owned GameForUri callback) {
		this.callback = (owned) callback;
	}

	public Game game_for_uri (Uri uri) throws Error {
		return callback (uri);
	}
}
