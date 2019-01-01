// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/sidebar-list-item.ui")]
private abstract class Games.SidebarListItem : Gtk.ListBoxRow {
	[GtkChild]
	protected Gtk.Label label;

	public abstract bool has_game (Game game);
}
