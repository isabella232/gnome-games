// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamGameData : Object {
	private HashTable<string, string> games;

	construct {
		games = new HashTable<string, string> (str_hash, str_equal);
	}

	public void add_game (string appid, string title) {
		games[appid] = title;
	}

	public string[] get_appids () {
		return games.get_keys_as_array ();
	}

	public string get_title (string appid) {
		return games[appid];
	}
}
