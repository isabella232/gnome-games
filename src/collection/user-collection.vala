// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.UserCollection : Object, Collection {
	private GameModel game_model;
	private Database database;
	private GenericSet<Uid> load_game_uids;
	private GenericSet<Uid> game_uids;
	private GameCollection game_collection;
	private string id;
	private ulong idle_id = 0;
	private ulong on_game_added_id = 0;

	public bool is_empty {
		get { return false; }
	}

	private string _title;
	public string title {
		get { return _title; }
	}

	public UserCollection (string id, string title, Database database) {
		this.id = id;
		_title = title;
		this.database = database;

		game_uids = new GenericSet<Uid> (Uid.hash, Uid.equal);

		game_collection = Application.get_default ().get_collection ();
		on_game_added_id = game_collection.game_added.connect (on_game_added);
		game_collection.game_removed.connect (on_game_removed);
		game_collection.game_replaced.connect (on_game_replaced);

		game_model = new GameModel ();
		game_model.always_replace = true;
	}

	public string get_id () {
		return id;
	}

	public void set_title (string value) {
		if (title == value)
			return;

		try {
			if (database.rename_user_collection (this, value)) {
				_title = value;
				notify_property ("title");
			}
		}
		catch (Error e) {
			critical ("%s", e.message);

			return;
		}
	}

	public GameModel get_game_model () {
		return game_model;
	}

	public bool get_hide_stars () {
		return false;
	}

	public CollectionType get_collection_type () {
		return USER;
	}

	public void load () {
		try {
			load_game_uids = database.list_games_in_user_collection (this);
			load_game_uids.foreach ((uid) => game_uids.add (uid));
		}
		catch (Error e) {
			critical ("Failed to load favorite game uids: %s", e.message);
		}
	}

	public void add_games (Game[] games) {
		try {
			foreach (var game in games)
				if (database.add_game_to_user_collection (game, this))
					game_model.add_game (game);

			games_changed ();
		}
		catch (Error e) {
			critical ("Failed to add games to user collection: %s", e.message);
		}
	}

	public void remove_games (Game[] games) {
		try {
			foreach (var game in games)
				if (database.remove_game_from_user_collection (game, this))
					game_model.remove_game (game);

			games_changed ();
		}
		catch (Error e) {
			critical ("Failed to remove games from user collection: %s", e.message);
		}
	}

	public void on_game_added (Game game) {
		if (load_game_uids.remove (game.uid)) {
			game_model.add_game (game);

			if (idle_id == 0)
				idle_id = Idle.add (() => {
					games_changed ();
					idle_id = 0;
					return Source.REMOVE;
				});

			if (load_game_uids.length == 0)
				game_collection.disconnect (on_game_added_id);
		}
	}

	public void on_game_removed (Game game) {
		game_model.remove_game (game);
		games_changed ();
	}

	public void on_game_replaced (Game game, Game prev_game) {
		if (game_uids.contains (prev_game.uid))
			game_model.replace_game (game, prev_game);
	}
}
