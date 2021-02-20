// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/preferences/preferences-page-platforms.ui")]
private class Games.PreferencesPagePlatforms : PreferencesPage {
	[GtkChild]
	private unowned Hdy.PreferencesGroup platforms_group;

	construct {
		var register = PlatformRegister.get_register ();
		var platforms = register.get_all_platforms ();

		foreach (var platform in platforms) {
			var row = platform.get_row ();
			row.show ();

			platforms_group.add (row);
		}
	}
}
