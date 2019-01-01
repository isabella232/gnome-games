private class Games.DeveloperListItem: Games.SidebarListItem {
	private Developer _developer;
	public Developer developer {
		get { return _developer; }
		set {
			_developer = value;
			update_label ();
			value.changed.connect (update_label);
		}
	}

	public DeveloperListItem (Developer developer) {
		Object (developer: developer);
	}

	public override bool has_game (Game game) {
		string game_developer = game.get_developer ().get_developer ();

		return (game_developer == developer.get_developer ());
	}

	private void update_label () {
		var val = developer.get_developer ();
		label.label = val == "" ? _("Unknown") : val;
	}

	public static int compare (DeveloperListItem a, DeveloperListItem b) {
		return a.developer.get_developer ().collate (b.developer.get_developer ());
	}
}
