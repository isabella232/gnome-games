// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/savestate-listbox-row.ui")]
private class Games.SavestateListBoxRow : Gtk.ListBoxRow {
	public const int THUMBNAIL_SIZE = 64;

	[GtkChild]
	private Gtk.Image image;
	[GtkChild]
	private Gtk.Label name_label;
	[GtkChild]
	private Gtk.Label date_label;

	private Savestate _savestate;
	public Savestate savestate {
		get { return _savestate; }
		set {
			_savestate = value;

			if (savestate.is_automatic ())
				name_label.label = _("Autosave");
			else
				name_label.label = savestate.get_name ();

			var creation_date = savestate.get_creation_date ();

			/* Translators: this is the day number followed
             * by the abbreviated month name followed by the year followed
             * by a time in 24h format i.e. "3 Feb 2015 23:04:00" */
            /* xgettext:no-c-format */
			date_label.label = creation_date.format (_("%-e %b %Y %X"));

			// Load the savestate thumbnail
			var screenshot_path = savestate.get_screenshot_path ();
			var screenshot_width = 0;
			var screenshot_height = 0;

			Gdk.Pixbuf.get_file_info (screenshot_path, out screenshot_width, out screenshot_height);

			var aspect_ratio = (double) savestate.get_screenshot_aspect_ratio ();

			// A fallback for migrated savestates
			if (aspect_ratio == 0)
				aspect_ratio = (double) screenshot_width / screenshot_height;

			// Calculate the thumbnail width and height
			var thumbnail_width = screenshot_width;
			var thumbnail_height = (int) (screenshot_width / aspect_ratio);

			if (thumbnail_width > thumbnail_height) {
				thumbnail_width = THUMBNAIL_SIZE;
				thumbnail_height = (int) (THUMBNAIL_SIZE / aspect_ratio);
			}
			else {
				thumbnail_height = THUMBNAIL_SIZE;
				thumbnail_width = (int) (THUMBNAIL_SIZE * aspect_ratio);
			}

			try {
				var thumbnail = new Gdk.Pixbuf.from_file_at_scale (screenshot_path,
				                                                   thumbnail_width,
				                                                   thumbnail_height,
				                                                   false);
				image.set_from_pixbuf (thumbnail);
			}
			catch (Error e) {
				warning ("Failed to load savestate thumbnail: %s", e.message);
			}
		}
	}

	public SavestateListBoxRow (Savestate savestate) {
		Object (savestate: savestate);
	}

	public void set_name (string name) {
		name_label.label = name;
		savestate.set_name (name);
	}
}

