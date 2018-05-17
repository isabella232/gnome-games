// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericGame : Object, Game {
	private string _name;
	public string name {
		get {
			try {
				_name = game_title.get_title ();
			}
			catch (Error e) {
				warning (e.message);
			}

			if (_name == null)
				_name = "";

			return _name;
		}
	}

	private Uid game_uid;
	private Title game_title;
	private Icon game_icon;
	private Cover game_cover;
	private ReleaseDate game_release_date;
	private Cooperative game_cooperative;
	private Genre game_genre;
	private Players game_players;
	private Runner game_runner;

	public GenericGame (Uid uid, Title title, Icon icon, Cover cover, ReleaseDate release_date, Cooperative cooperative, Genre genre, Players players, Runner runner) {
		game_uid = uid;
		game_title = title;
		game_icon = icon;
		game_cover = cover;
		game_release_date = release_date;
		game_cooperative = cooperative;
		game_genre = genre;
		game_players = players;
		game_runner = runner;
	}

	public Uid get_uid () {
		return game_uid;
	}

	public Icon get_icon () {
		return game_icon;
	}

	public Cover get_cover () {
		return game_cover;
	}

	public ReleaseDate get_release_date () {
		return game_release_date;
	}

	public Cooperative get_cooperative () {
		return game_cooperative;
	}

	public Genre get_genre () {
		return game_genre;
	}

	public Players get_players () {
		return game_players;
	}

	public Runner get_runner () throws Error {
		return game_runner;
	}
}
