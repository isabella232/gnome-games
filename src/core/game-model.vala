// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameModel : Object, ListModel {
	public signal void game_added (Game game);

	private Sequence<Game> sequence;
	private int n_games;

	construct {
		sequence = new Sequence<Game> ();
		n_games = 0;
	}

	public Object? get_item (uint position) {
		var iter = sequence.get_iter_at_pos ((int) position);

		return iter.get ();
	}

	public Type get_item_type () {
		return typeof (Game);
	}

	public uint get_n_items () {
		return n_games;
	}

	public void add_game (Game game) {
		var iter = sequence.insert_sorted (game, compare_func);
		n_games++;

		items_changed (iter.get_position (), 0, 1);
		game_added (game);
	}

	private int compare_func (Game a, Game b) {
		return a.name.collate (b.name);
	}
}
