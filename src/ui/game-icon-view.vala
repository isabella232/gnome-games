// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.Box {
	[GtkChild]
	private GameThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label title;

	public Game game { get; construct; }

	construct {
		thumbnail.uid = game.get_uid ();
		thumbnail.icon = game.get_icon ();
		thumbnail.cover = game.get_cover ();
		title.label = game.name;
	}

	public GameIconView (Game game) {
		Object (game: game);
	}
}
