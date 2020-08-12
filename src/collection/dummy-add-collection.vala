// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DummyAddCollection : Object, Collection {
	public bool is_empty {
		get { return true; }
	}

	public string title {
		get { return _("Add Collection"); }
	}

	public string get_id () {
		return "Add Collection";
	}

	public GameModel get_game_model () {
		return new GameModel ();
	}

	public bool get_hide_stars () {
		return true;
	}

	public CollectionType get_collection_type () {
		return PLACEHOLDER;
	}

	public void load () {
	}

	public void add_games (Game[] games) {
	}

	public void remove_games (Game[] games) {
	}

	public void on_game_added (Game game) {
	}

	public void on_game_removed (Game game) {
	}

	public void on_game_replaced (Game game, Game prev_game) {
	}
}
