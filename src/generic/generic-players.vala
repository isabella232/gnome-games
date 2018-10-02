// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlayers : Object, Players {
	private string players;

	public bool has_loaded { get; protected set; }

	construct {
		has_loaded = true;
	}

	public GenericPlayers (string players) {
		this.players = players;
	}

	public string get_players () {
		return players;
	}
}
