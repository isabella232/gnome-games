// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-platforms-retro-row.ui")]
private class Games.PreferencesPagePlatformsRetroRow : PreferencesPagePlatformsRow, Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label name_label;
	[GtkChild]
	private Gtk.Label core_label;
	[GtkChild]
	private Gtk.Popover details_popover;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private Gtk.Image dropdown_arrow;

	private Settings settings;

	private HashTable<Gtk.Widget, Retro.CoreDescriptor> row_cores;
	private int num_cores;

	public RetroPlatform platform { get; construct; }

	construct {
		list_box.set_header_func (update_header);

		name_label.label = platform.get_name ();

		refresh_cores ();

		var path = "/org/gnome/Games/platforms/%s/".printf (platform.get_id ());
		settings = new Settings.with_path ("org.gnome.Games.platforms", path);

		settings.changed.connect (update_label);
	}

	public PreferencesPagePlatformsRetroRow (RetroPlatform platform) {
		Object (platform: platform);
	}

	private void update_label () {
		var core_manager = RetroCoreManager.get_instance ();
		var preferred_core = core_manager.get_preferred_core (platform);

		if (preferred_core == null)
			core_label.label = _("None");
		else {
			try {
				core_label.label = preferred_core.get_name ();
			}
			catch (Error e) {
				critical (e.message);
				core_label.label = _("None");
			}
		}
	}

	private void refresh_cores () {
		var core_manager = RetroCoreManager.get_instance ();
		var cores = core_manager.get_cores_for_platform (platform);

		num_cores = cores.length;

		sensitive = (num_cores > 0);
		dropdown_arrow.visible = (num_cores > 1);

		row_cores = new HashTable<Gtk.Widget, Retro.CoreDescriptor> (null, null);

		foreach (var core in cores) {
			try {
				var label = new Gtk.Label (core.get_name ());
				label.halign = Gtk.Align.START;
				label.margin = 12;
				label.show ();

				var row = new Gtk.ListBoxRow ();
				row.add (label);
				row.show ();
				row_cores[row] = core;

				list_box.add (row);
			}
			catch (Error e) {
				critical (e.message);
			}
		}

		update_label ();
	}

	public void on_activated () {
		if (num_cores <= 1)
			return;

		details_popover.popup ();
	}

	private void update_header (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
		if (before != null && row.get_header () == null) {
			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			row.set_header (separator);
		}
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow row) {
		var core = row_cores[row];

		var core_manager = RetroCoreManager.get_instance ();
		core_manager.set_preferred_core (platform, core);

		details_popover.popdown ();
	}
}
