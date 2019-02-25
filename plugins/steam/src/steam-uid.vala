// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamUid : Object, Uid {
	private string uid;
	private string prefix;
	private string game_id;

	public SteamUid (string prefix, string game_id) {
		this.prefix = prefix;
		this.game_id = game_id;
	}

	public string get_uid () throws Error {
		if (uid != null)
			return uid;

		uid = @"steam-$prefix$game_id".down ();

		return uid;
	}
}
