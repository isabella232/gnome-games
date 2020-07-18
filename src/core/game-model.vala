// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameModel : Object, ListModel {
	public signal void game_added (Game game);
	public signal void game_removed (Game game);

	private Sequence<Game> sequence;
	private int n_games;
	private CompareDataFunc<Game> compare_func;

	public bool always_replace;

	public enum SortType {
		BY_NAME,
		BY_LAST_PLAYED;

		public CompareDataFunc<Game> get_sort_function () {
			switch (this) {
			case BY_NAME:
				return Game.compare;

			case BY_LAST_PLAYED:
				return Game.compare_by_date_time;

			default:
				assert_not_reached ();
			}
		}
	}

	private SortType _sort_type = BY_NAME;
	public SortType sort_type {
		get { return _sort_type; }
		set {
			if (sort_type == value)
				return;

			_sort_type = value;

			compare_func = sort_type.get_sort_function ();
			sequence.sort (compare_func);
			items_changed (0, n_games, n_games);
		}
	}

	construct {
		compare_func = sort_type.get_sort_function ();
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

	public void replace_game (Game game, Game prev_game) {
		// Title changed, just hope it doesn't happen too often
		// FIX ME always_replace is a temporary hack until on_game_replaced is redone
		if (prev_game.name != game.name || always_replace) {
			remove_game (prev_game);
			add_game (game);

			return;
		}

		// Title didn't change, try to make it seamless
		prev_game.replaced (game);
	}

	public void remove_game (Game game) {
		SequenceIter<Game> iter = null;
		// Might be expensive so only do it when sequence is sorted by recently played
		if (sort_type == BY_LAST_PLAYED)
			iter = get_game_iter (game);
		else
			iter = sequence.lookup (game, compare_func);

		if (iter == null)
			return;

		if (iter == null)
			return;

		var pos = iter.get_position ();
		iter.remove ();
		n_games--;

		items_changed (pos, 1, 0);
		game_removed (game);
	}

	private SequenceIter<Game>? get_game_iter (Game game) {
		for (var iter = sequence.get_begin_iter (); !iter.is_end (); iter = iter.next ())
			if (Game.equal (iter.get (), game))
				return iter;

		return null;
	}
}
