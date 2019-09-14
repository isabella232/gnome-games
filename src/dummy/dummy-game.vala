// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DummyGame : Object, Game {
	private string _name;
	public string name {
		get { return _name; }
	}

	public DummyGame (string name) {
		_name = name;
	}

	public DummyGame.for_uri (Uri uri) {
		var file = uri.to_file ();
		var name = file.get_basename ();
		name = name.split (".")[0];
		name = name.split ("(")[0];
		_name = name.strip ();
	}

	public Uid get_uid () {
		return new DummyUid ();
	}

	public Icon get_icon () {
		return new DummyIcon ();
	}

	public Cover get_cover () {
		return new DummyCover ();
	}

	public ReleaseDate get_release_date () {
		return new DummyReleaseDate ();
	}

	public Players get_players () {
		return new DummyPlayers ();
	}

	public Developer get_developer () {
		return new DummyDeveloper ();
	}

	public Rating get_rating () {
		return new DummyRating ();
	}

	public Platform get_platform () {
		return new DummyPlatform ();
	}

	public Runner get_runner () throws Error {
		return new DummyRunner ();
	}
}
