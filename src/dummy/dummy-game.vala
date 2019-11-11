// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DummyGame : Object, Game {
	private Uri uri;
	private string _name;
	public string name {
		get { return _name; }
	}

	public DummyGame (string name) {
		uri = new Uri ("");
		_name = name;
	}

	public DummyGame.for_uri (Uri uri) {
		this.uri = uri;

		var file = uri.to_file ();
		var name = file.get_basename ();
		name = name.split (".")[0];
		name = name.split ("(")[0];
		_name = name.strip ();
	}

	public Uid get_uid () {
		return new DummyUid ();
	}

	public Uri get_uri () {
		return uri;
	}

	public Icon get_icon () {
		return new DummyIcon ();
	}

	public Cover get_cover () {
		return new DummyCover ();
	}

	public Platform get_platform () {
		return new DummyPlatform ();
	}
}
