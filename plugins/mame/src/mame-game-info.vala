// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MameGameInfo {
	private static HashTable<string, string> supported_games;

	public static HashTable<string, string> get_supported_games () throws Error {
		if (supported_games != null)
			return supported_games;

		supported_games = new HashTable<string, string> (str_hash, str_equal);

		var bytes = resources_lookup_data ("/org/gnome/Games/plugins/mame/supported-games", ResourceLookupFlags.NONE);
		var text = (string) bytes.get_data ();

		var lines = text.split ("\n");
		foreach (var line in lines) {
			var parts = line.split (" ", 2);

			if (parts.length < 2)
				continue;

			var id = parts[0];
			var name = parts[1];

			supported_games[id] = name;
		}

		return supported_games;
	}
}
