// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/platform-list-item.ui")]
private class Games.PlatformListItem : Gtk.ListBoxRow {
	[GtkChild]
	protected Gtk.Label label;

	private Platform _platform;
	public Platform platform {
		get { return _platform; }
		construct {
			_platform = value;
			label.label = value.get_name ();
		}
	}

	public PlatformListItem (Platform platform) {
		Object (platform: platform);
	}

	public static int compare (PlatformListItem a, PlatformListItem b) {
		return a.platform.get_name ().collate (b.platform.get_name ());
	}
}
