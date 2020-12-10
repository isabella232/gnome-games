// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/preferences/preferences-page-video.ui")]
private class Games.PreferencesPageVideo : PreferencesPage {
	private string _filter_active;
	public string filter_active {
		set {
			for (var i = 0; i < filter_names.length; i++) {
				filter_radios[i].active = (value == filter_names[i]);
			}
			_filter_active = value;
		}

		get {
			return _filter_active;
		}
	}

	[GtkChild]
	private Hdy.PreferencesGroup filter_group;

	// same as video-filters in gschema
	/* Translators: These values are video filters applied to the screen. Smooth
	* tries to smoothen the pixels, sharp displays the pixels square, and CRT
	* emulates an old TV */
	private string[] filter_display_names = { _("Smooth"), _("Sharp"), _("CRT") };
	private string[] filter_names = { "smooth", "sharp", "crt" };

	private Settings settings;
	private Gtk.RadioButton filter_radios[3];

	construct {
		for (var i = 0; i < filter_display_names.length; i++) {
			var row = new Hdy.ActionRow ();
			row.title = filter_display_names [i];

			filter_radios[i] = new Gtk.RadioButton.from_widget (filter_radios[0]);
			filter_radios[i].name = filter_names[i];
			filter_radios[i].valign = Gtk.Align.CENTER;
			filter_radios[i].can_focus = false;
			filter_radios[i].toggled.connect ((radio) => {
				if (!radio.active)
					return;

				filter_active = radio.name;
			});

			row.add_prefix (filter_radios[i]);
			row.activatable_widget = filter_radios[i];
			row.show_all ();

			row.activated.connect (() => {
				filter_active = filter_names[i];
			});

			filter_group.add (row);
		}

		settings = new Settings ("org.gnome.Games");
		settings.bind ("video-filter", this, "filter-active",
		               SettingsBindFlags.DEFAULT);
	}
}
