// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.Collection : Object {
	// Collection types are in decreasing order of precedence while comparing between them.
	public enum CollectionType {
		AUTO,
		USER,
		PLACEHOLDER
	}

	public signal void games_changed ();

	public abstract bool is_empty { get; }

	public abstract string title { get; }

	public abstract void load ();

	public abstract string get_id ();

	public abstract bool get_hide_stars ();

	public abstract GameModel get_game_model ();

	public abstract CollectionType get_collection_type ();

	public abstract void add_games (Game[] games);

	public abstract void remove_games (Game[] games);

	public abstract void on_game_added (Game game);

	public abstract void on_game_removed (Game game);

	public abstract void on_game_replaced (Game game, Game prev_game);

	public bool matches_search_terms (string[] search_terms) {
		var name = title;
		if (search_terms.length != 0)
			foreach (var term in search_terms)
				if (!(term.casefold () in name.casefold ()))
					return false;

		return true;
	}

	public static uint hash (Collection collection) {
		return str_hash (collection.get_id ());
	}

	public static bool equal (Collection a, Collection b) {
		if (direct_equal (a, b))
			return true;

		return str_equal (a.get_id (), b.get_id ());
	}

	public static int compare (Collection a, Collection b) {
		var title_a = a.title;
		var title_b = b.title;
		var type_a = a.get_collection_type ();
		var type_b = b.get_collection_type ();

		if (type_a == type_b)
			return title_a.collate (title_b);

		return type_a < type_b ? -1 : 1;
	}
}
