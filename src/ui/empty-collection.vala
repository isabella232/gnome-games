// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/empty-collection.ui")]
private class Games.EmptyCollection : Gtk.Box {
	[GtkChild]
	private Gtk.Image icon;

	construct {
		var icon_name = Config.APPLICATION_ID + "-symbolic";
		icon.icon_name = icon_name;
	}
}
