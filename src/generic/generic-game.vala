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
	private Developer game_developer;
	private Description game_description;
	private Rating game_rating;
	private Cover game_cover;
	private ReleaseDate game_release_date;
	private Cooperative game_cooperative;
	private Genre game_genre;
	private Players game_players;
	private Platform game_platform;
	private Runner game_runner;

	public GenericGame (Uid uid, Title title, Platform platform, Runner runner) {
		game_uid = uid;
		game_title = title;
		game_runner = runner;
		game_platform = platform;
	}

	public Uid get_uid () {
		return game_uid;
	}

	public Icon get_icon () {
		if (game_icon == null)
			game_icon = new DummyIcon ();

		return game_icon;
	}

	public void set_icon (Icon icon) {
		game_icon = icon;
	}

	public Cover get_cover () {
		if (game_cover == null)
			game_cover = new DummyCover ();

		return game_cover;
	}

	public void set_cover (Cover cover) {
		game_cover = cover;
	}

	public ReleaseDate get_release_date () {
		if (game_release_date == null)
			game_release_date = new DummyReleaseDate ();

		return game_release_date;
	}

	public void set_release_date (ReleaseDate release_date) {
		game_release_date = release_date;
	}

	public Cooperative get_cooperative () {
		if (game_cooperative == null)
			game_cooperative = new DummyCooperative ();

		return game_cooperative;
	}

	public void set_cooperative (Cooperative cooperative) {
		game_cooperative = cooperative;
	}

	public Genre get_genre () {
		if (game_genre == null)
			game_genre = new DummyGenre ();

		return game_genre;
	}

	public void set_genre (Genre genre) {
		game_genre = genre;
	}

	public Players get_players () {
		if (game_players == null)
			game_players = new DummyPlayers ();

		return game_players;
	}

	public void set_players (Players players) {
		game_players = players;
	}

	public Developer get_developer () {
		if (game_developer == null)
			game_developer = new DummyDeveloper ();

		return game_developer;
	}

	public void set_developer (Developer developer) {
		game_developer = developer;
	}

	public Description get_description () {
		if (game_description == null)
			game_description = new DummyDescription ();

		return game_description;
	}

	public void set_description (Description description) {
		game_description = description;
	}

	public Rating get_rating () {
		if (game_rating == null)
			game_rating = new DummyRating ();

		return game_rating;
	}

	public void set_rating (Rating rating) {
		game_rating = rating;
	}

	public Platform get_platform () {
		return game_platform;
	}

	public Runner get_runner () throws Error {
		return game_runner;
	}
}
