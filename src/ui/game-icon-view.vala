// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.Box {
	[GtkChild]
	private GameThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label title;

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

			game_replaced_id = game.replaced.connect (game_replaced);
		}
	}

	public GameIconView (Game game) {
		Object (game: game);
	}

	private void game_replaced (Game new_game) {
		game = new_game;
	}
}
