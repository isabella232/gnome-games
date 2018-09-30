[GtkTemplate (ui = "/org/gnome/Games/ui/developer-list-item.ui")]
private class Games.DeveloperListItem: Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label label;

	private Developer _developer;
	public Developer developer {
		get { return _developer; }
		set {
			_developer = value;
			update_label ();
		}
	}

	public DeveloperListItem (Developer developer) {
		Object (developer: developer);
	}

	private void update_label () {
		var val = developer.get_developer ();
		label.label = val == "" ? _("Unknown") : val;
	}

	public static int compare (DeveloperListItem a, DeveloperListItem b) {
		return a.developer.get_developer ().collate (b.developer.get_developer ());
	}
}
