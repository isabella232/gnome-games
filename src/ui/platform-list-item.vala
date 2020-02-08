// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/platform-list-item.ui")]
private class Games.PlatformListItem : Gtk.ListBoxRow {
	[GtkChild]
	protected Gtk.Label label;

	public Platform platform { get; construct; }

	construct {
		label.label = platform.get_name ();
	}

	public PlatformListItem (Platform platform) {
		Object (platform: platform);
	}
}
