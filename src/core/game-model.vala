// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameModel : Object, ListModel {
	public signal void game_added (Game game);
	public signal void game_removed (Game game);

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
		var iter = sequence.insert_sorted (game, Game.compare);
		n_games++;

		items_changed (iter.get_position (), 0, 1);
		game_added (game);
	}

	public void replace_game (Game game, Game prev_game) {
		// Title changed, just hope it doesn't happen too often
		if (prev_game.name != game.name) {
			remove_game (prev_game);
			add_game (game);

			return;
		}

		// Title didn't change, try to make it seamless
		prev_game.replaced (game);
	}

	public void remove_game (Game game) {
		var iter = sequence.lookup (game, Game.compare);

		var pos = iter.get_position ();
		iter.remove ();
		n_games--;

		items_changed (pos, 1, 0);
		game_removed (game);
	}
}
