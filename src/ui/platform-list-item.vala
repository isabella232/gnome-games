[GtkTemplate (ui = "/org/gnome/Games/ui/platform-list-item.ui")]
private class Games.PlatformListItem: Gtk.Label {
	private Platform _platform;
	public Platform platform {
		get { return _platform; }
		set {
			_platform = value;
			label = value.get_name ();
		}
	}

	public PlatformListItem (Platform platform) {
		Object (platform : platform);
	}

	public static int compare (PlatformListItem a, PlatformListItem b) {
		return a.platform.get_name ().collate (b.platform.get_name ());
	}
}
