// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-sidebar-item.ui")]
private class Games.PreferencesSidebarItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label label;

	public PreferencesPage preferences_page { get; construct; }

	construct {
		label.label = preferences_page.title;
	}

	public PreferencesSidebarItem (PreferencesPage preferences_page) {
		Object (preferences_page : preferences_page);
	}
}
