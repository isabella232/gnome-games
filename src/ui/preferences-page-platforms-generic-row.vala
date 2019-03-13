// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-platforms-generic-row.ui")]
private class Games.PreferencesPagePlatformsGenericRow : PreferencesPagePlatformsRow, Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label title_label;

	public string title {
		get { return title_label.label; }
		construct set {
			title_label.label = value;
		}
	}

	public PreferencesPagePlatformsGenericRow (string title) {
		Object (title:title);
	}

	public void on_activated () {
	}
}
