// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.Box {
	[GtkChild]
	private GameThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label title;

	public Game game { get; construct; }

	construct {
		thumbnail.game = game;
		title.label = game.name;
	}

	public GameIconView (Game game) {
		Object (game: game);
	}
}
