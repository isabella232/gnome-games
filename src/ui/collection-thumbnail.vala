// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-thumbnail.ui")]
private class Games.CollectionThumbnail : Gtk.Bin {
	// This should match the number of grid children in the template
	const uint N_ROWS = 2;
	const uint N_COLUMNS = 2;

	[GtkChild]
	private Gtk.Grid grid;

	private ulong games_changed_id = 0;

	private Collection _collection;
	public Collection collection {
		get { return _collection; }
		set {
			if (games_changed_id > 0)
				collection.disconnect (games_changed_id);

			_collection = value;

			games_changed_id = collection.games_changed.connect (on_games_changed);
		}
	}

	public void on_games_changed () {
		var max_subcovers = N_ROWS * N_COLUMNS;

		var children = grid.get_children ();
		children.reverse ();

		var pos = 0;
		var game_model = collection.get_game_model ();
		var n_games = game_model.get_n_items ();
		foreach (var child in children) {
			var event_box = child as Gtk.Bin;

			if (pos < n_games) {
				var game = game_model.get_item (pos) as Game;
				var game_thumbnail = get_game_thumbnail (game);

				var current_thumbnail = event_box.get_child ();
				if (current_thumbnail != null)
					event_box.remove (current_thumbnail);
				event_box.add (game_thumbnail);

				pos++;
				continue;
			}

			if (pos < max_subcovers) {
				var game_thumbnail = event_box.get_child ();
				if (game_thumbnail != null)
					event_box.remove (game_thumbnail);
				pos++;
			}
		}
	}

	private GameThumbnail? get_game_thumbnail (Game game) {
		var game_thumbnail = new GameThumbnail ();
		game_thumbnail.game = game;
		game.replaced.connect ((new_game) => {
			game_thumbnail.game = new_game;
		});
		game_thumbnail.visible = true;

		return game_thumbnail;
	}
}
