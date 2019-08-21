// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-platforms-generic-row.ui")]
private class Games.PreferencesPagePlatformsGenericRow : PreferencesPagePlatformsRow, Gtk.ListBoxRow {
	public string title { get; construct; }

	public PreferencesPagePlatformsGenericRow (string title) {
		Object (title: title);
	}

	public void on_activated () {
	}
}
