// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PlatformListItem : Games.SidebarListItem {
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

	public override bool has_game (Game game) {
		string game_platform = game.get_platform ().get_name ();

		return (game_platform == platform.get_name ());
	}

	public static int compare (PlatformListItem a, PlatformListItem b) {
		return a.platform.get_name ().collate (b.platform.get_name ());
	}
}
