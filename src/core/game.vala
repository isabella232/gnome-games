// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Game : Object {
	public signal void replaced (Game new_game);

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

	public Uid uid { get; private set; }
	public Uri uri { get; private set; }
	public Platform platform { get; private set; }
	public MediaSet? media_set { get; set; }

	private Title game_title;
	private Icon game_icon;
	private Cover game_cover;

	public Game (Uid uid, Uri uri, Title title, Platform platform) {
		this.uid = uid;
		this.uri = uri;
		game_title = title;
		this.platform = platform;
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

	public bool matches_search_terms (string[] search_terms) {
		if (search_terms.length != 0)
			foreach (var term in search_terms)
				if (!(term.casefold () in name.casefold ()))
					return false;

		return true;
	}

	public static uint hash (Game key) {
		return Uid.hash (key.uid);
	}

	public static bool equal (Game a, Game b) {
		if (direct_equal (a, b))
			return true;

		return Uid.equal (a.uid, b.uid);
	}

	public static int compare (Game a, Game b) {
		var ret = a.name.collate (b.name);
		if (ret != 0)
			return ret;

		ret = Platform.compare (a.platform, b.platform);
		if (ret != 0)
			return ret;

		var uid1 = a.uid.to_string ();
		var uid2 = b.uid.to_string ();

		return uid1.collate (uid2);
	}
}
