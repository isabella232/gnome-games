// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.FlowBoxChild {
	[GtkChild]
	private unowned GameThumbnail thumbnail;
	[GtkChild]
	private unowned Gtk.Label title;

	private ulong game_replaced_id;

	private Game _game;
	public Game game {
		get { return _game; }
		construct set {
			if (game == value)
				return;

			if (game_replaced_id > 0)
				game.disconnect (game_replaced_id);

			_game = value;

			thumbnail.game = game;
			title.label = game.name;

			game.bind_property ("is-favorite", this, "is-favorite", BindingFlags.SYNC_CREATE);
			game_replaced_id = game.replaced.connect (game_replaced);
		}
	}

	public bool checked { get; set; }
	public bool is_selection_mode { get; set; }
	public bool is_favorite { get; set; }

	public GameIconView (Game game) {
		Object (game: game);
	}

	private void game_replaced (Game new_game) {
		game = new_game;
	}

	public static uint hash (GameIconView key) {
		return Game.hash (key.game);
	}

	public static bool equal (GameIconView a, GameIconView b) {
		return Game.equal (a.game, b.game);
	}
}
