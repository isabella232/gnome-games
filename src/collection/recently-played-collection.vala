// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RecentlyPlayedCollection : Object, Collection {
	private GameModel game_model;

	private Database database;
	private GenericSet<Uid> game_uids;

	private bool _is_empty = true;
	public bool is_empty {
		get { return _is_empty; }
	}

	public string title {
		get { return _("Recently Played"); }
	}

	public RecentlyPlayedCollection (Database database) {
		this.database = database;

		var game_collection = Application.get_default ().get_collection ();
		game_collection.game_added.connect (on_game_added);
		game_collection.game_removed.connect (on_game_removed);
		game_collection.game_replaced.connect (on_game_replaced);

		game_model = new GameModel ();
		game_model.always_replace = true;
		game_model.sort_type = GameModel.SortType.BY_LAST_PLAYED;
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
		return "Recently Played";
	}

	public GameModel get_game_model () {
		return game_model;
	}

	public bool get_hide_stars () {
		return false;
	}

	public CollectionType get_collection_type () {
		return AUTO;
	}

	public void load () {
		try {
			game_uids = database.list_recently_played_games ();
		}
		catch (Error e) {
			critical ("Failed to load recently played game uids: %s", e.message);
		}
	}

	public void add_games (Game[] games) {
		try {
			foreach (var game in games) {
				// Remove game to prevent duplication of games in game-model
				game_model.remove_game (game);
				database.update_recently_played_game (game);
				game_model.add_game (game);
			}
		}
		catch (Error e) {
			critical (e.message);
		}

		games_changed ();
	}

	public void remove_games (Game[] games) {
		try {
			foreach (var game in games) {
				if (game.last_played == null)
					continue;

				database.update_recently_played_game (game, true);
				game_model.remove_game (game);
			}
		}
		catch (Error e) {
			critical (e.message);
		}

		games_changed ();
	}

	public void on_game_added (Game game) {
		game.notify["last-played"].connect (() => {
			add_games ({ game });
		});

		if (game_uids.remove (game.uid)) {
			game_model.add_game (game);
			games_changed ();
		}
	}

	public void on_game_removed (Game game) {
		remove_games ({ game });
		games_changed ();
	}

	public void on_game_replaced (Game game, Game prev_game) {
		if (prev_game.last_played != null) {
			game.last_played = prev_game.last_played;
			game_model.replace_game (game, prev_game);
		}

		SignalHandler.disconnect_by_data (prev_game, this);
		game.notify["last-played"].connect (() => {
			add_games ({ game });
		});
	}
}
