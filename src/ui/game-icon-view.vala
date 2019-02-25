// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.Box {
	private Game _game;
	public Game game {
		get { return _game; }
		construct {
			_game = value;

			thumbnail.uid = game.get_uid ();
			thumbnail.icon = game.get_icon ();
			thumbnail.cover = game.get_cover ();
			title.label = game.name;
		}
	}

	[GtkChild]
	private GameThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label title;

	public GameIconView (Game game) {
		Object (game: game);
	}
}
