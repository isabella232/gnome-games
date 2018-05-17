// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlayers : Object, Players {
	private string players;

	public GenericPlayers (string players) {
		this.players = players;
	}

	public string get_players () {
		return players;
	}
}
