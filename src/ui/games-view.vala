// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GamesView : SidebarView {
	protected override void game_added (Game game) {}

	protected override void invalidate (Gtk.ListBoxRow row_item) {}

	protected override int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		return 0;
	}
}
