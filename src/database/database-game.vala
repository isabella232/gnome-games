// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DatabaseGame : Object, Game {
	private string game_title;
	public string name {
		get { return game_title; }
	}

	private Uid game_uid;
	private Uri game_uri;
	private Platform game_platform;
	private MediaSet game_media_set;

	public DatabaseGame (string uid, string uri, string title, string platform, string? media_set) {
		game_uid = new GenericUid (uid);
		game_uri = new Uri (uri);
		game_title = title;
		game_platform = PlatformRegister.get_register ().get_platform (platform);

		if (media_set != null)
			game_media_set = new MediaSet.parse (new Variant.parsed (media_set));
	}

	public Uid get_uid () {
		return game_uid;
	}

	public Uri get_uri () {
		return game_uri;
	}

	public MediaSet? get_media_set () {
		return game_media_set;
	}

	public Icon get_icon () {
		return new DummyIcon ();
	}

	public Cover get_cover () {
		return new DummyCover ();
	}

	public Platform get_platform () {
		return game_platform;
	}
}
