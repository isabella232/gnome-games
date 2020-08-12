// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.FavoritesCollection : Object, Collection {
	private GameModel game_model;

	private Database database;
	private GenericSet<Uid> favorite_game_uids;

	private bool _is_empty = true;
	public bool is_empty {
		get { return _is_empty; }
	}

	public string title {
		get { return _("Favorites"); }
	}

	private ulong idle_id = 0;

	public FavoritesCollection (Database database) {
		this.database = database;

		var game_collection = Application.get_default ().get_collection ();
		game_collection.game_added.connect (on_game_added);
		game_collection.game_removed.connect (on_game_removed);
		game_collection.game_replaced.connect (on_game_replaced);

		game_model = new GameModel ();
		game_model.always_replace = true;
		game_model.game_added.connect (() => {
			set_is_empty (false);
		});
		game_model.game_removed.connect (() => {
			set_is_empty (game_model.get_n_items () == 0);
		});
	}

	private void set_is_empty (bool value) {
		if (is_empty == value)
			return;

		_is_empty = value;
		notify_property ("is-empty");
	}

	public string get_id () {
		return "Favorites";
	}

	public GameModel get_game_model () {
		return game_model;
	}

	public bool get_hide_stars () {
		return true;
	}

	public CollectionType get_collection_type () {
		return AUTO;
	}

	public void load () {
		try {
			favorite_game_uids = database.list_favorite_games ();
		}
		catch (Error e) {
			critical ("Failed to load favorite game uids: %s", e.message);
		}
	}

	public void add_games (Game[] games) {
		foreach (var game in games)
			game.is_favorite = true;
	}

	public void remove_games (Game[] games) {
		foreach (var game in games)
			game.is_favorite = false;
	}

	private void on_is_favorite_changed (Game game) {
		try {
			// Only add/remove games from game_model only if they aren't
			// favorite/non-favorite already. This helps to avoid duplicate
			// thumbnails when using the inspector etc.
			if (database.set_is_favorite (game)) {
				if (game.is_favorite)
					game_model.add_game (game);
				else
					game_model.remove_game (game);

				if (idle_id == 0)
					idle_id = Idle.add (() => {
						games_changed();
						idle_id = 0;
						return Source.REMOVE;
					});
			}
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void on_game_added (Game game) {
		game.notify["is-favorite"].connect (() => {
			on_is_favorite_changed (game);
		});

		if (favorite_game_uids.remove (game.uid)) {
			game_model.add_game (game);
			games_changed ();
		}
	}

	public void on_game_removed (Game game) {
		game_model.remove_game (game);
		games_changed ();
	}

	public void on_game_replaced (Game game, Game prev_game) {
		if (prev_game.is_favorite) {
			game.is_favorite = true;
			game_model.replace_game (game, prev_game);
		}

		SignalHandler.disconnect_by_data (prev_game, this);
		game.notify["is-favorite"].connect (() => {
			on_is_favorite_changed (game);
		});
	}
}
