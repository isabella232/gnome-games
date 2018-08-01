[GtkTemplate (ui = "/org/gnome/Games/ui/developer-list-item.ui")]
private class Games.DeveloperListItem: Gtk.Label {
	private Developer _developer;
	public Developer developer {
		get { return _developer; }
		set {
			_developer = value;
			label = value.get_developer ();
		}
	}

	public DeveloperListItem (Developer developer) {
		Object (developer: developer);
	}
}
