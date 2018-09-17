// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/search-bar.ui")]
private class Games.SearchBar : Gtk.Bin {
	public string text { get; private set; }
	public bool search_mode_enabled { get; set; }

	[GtkChild]
	private Gtk.SearchBar search_bar;
	[GtkChild]
	private Gtk.SearchEntry entry;

	construct {
		search_bar.connect_entry (entry);
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

	public bool handle_event (Gdk.Event event) {
		return search_bar.handle_event (event);
	}
}
