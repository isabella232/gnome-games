// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/search-bar.ui")]
private class Games.SearchBar : Hdy.SearchBar {
	public string text { get; private set; }

	[GtkChild]
	private Gtk.SearchEntry entry;

	construct {
		connect_entry (entry);
	}

	[GtkCallback]
	private void on_search_changed () {
		text = entry.text;
	}

	[GtkCallback]
	private void on_search_activated () {
		text = entry.text;
	}

	public void focus_entry () {
		entry.grab_focus_without_selecting ();
	}
}
