// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/game-icon-view.ui")]
private class Games.GameIconView : Gtk.Box {
	private Game _game;
	public Game game {
		get { return _game; }
		set {
			if (value == game)
				return;

			_game = value;

			thumbnail.uid = game.get_uid ();
			thumbnail.icon = game.get_icon ();
			thumbnail.cover = game.get_cover ();
			title.label = game.name;

			queue_draw ();
		}
	}

	public int size {
		set {
			thumbnail.width_request = value;
			thumbnail.height_request = value;
			title.width_request = value;
			subtitle.width_request = value;
		}
	}

	[GtkChild]
	private GameThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.Label subtitle;

	public GameIconView (Game game) {
		this.game = game;
		this.size = 256;
	}
}
