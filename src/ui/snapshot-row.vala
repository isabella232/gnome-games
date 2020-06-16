// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/snapshot-row.ui")]
private class Games.SnapshotRow : Gtk.ListBoxRow {
	public const int THUMBNAIL_SIZE = 64;

	[GtkChild]
	private Gtk.DrawingArea image;
	[GtkChild]
	private Gtk.Label name_label;
	[GtkChild]
	private Gtk.Label date_label;
	[GtkChild]
	private Gtk.Revealer revealer;

	private Snapshot _snapshot;
	public Snapshot snapshot {
		get { return _snapshot; }
		set {
			_snapshot = value;

			if (snapshot.is_automatic)
				name_label.label = _("Autosave");
			else
				name_label.label = snapshot.name;

			var creation_date = snapshot.creation_date;
			var date_format = get_date_format (creation_date);
			date_label.label = creation_date.format (date_format);

			load_thumbnail ();
		}
	}

	private Gdk.Pixbuf pixbuf;

	public SnapshotRow (Snapshot snapshot) {
		Object (snapshot: snapshot);
	}

	private void load_thumbnail () {
		if (snapshot == null)
			return;

		var screenshot_path = snapshot.get_screenshot_path ();
		var screenshot_width = 0;
		var screenshot_height = 0;

		Gdk.Pixbuf.get_file_info (screenshot_path, out screenshot_width, out screenshot_height);

		var aspect_ratio = 1.0;//snapshot.screenshot_aspect_ratio;

		// A fallback for migrated snapshots
		if (aspect_ratio == 0)
			aspect_ratio = (double) screenshot_width / screenshot_height;

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

		thumbnail_width *= scale_factor;
		thumbnail_height *= scale_factor;

		try {
			pixbuf = new Gdk.Pixbuf.from_file_at_scale (screenshot_path,
			                                            thumbnail_width,
			                                            thumbnail_height,
			                                            false);
		}
		catch (Error e) {
			warning ("Failed to load snapshot thumbnail: %s", e.message);
		}
	}

	[GtkCallback]
	private void on_scale_factor_changed () {
		load_thumbnail ();
	}

	public void set_name (string name) {
		name_label.label = name;
		snapshot.name = name;

		try {
			snapshot.write_metadata ();
		}
		catch (Error e) {
			critical ("Couldn't update snapshot name: %s", e.message);
		}
	}

	public void reveal () {
		revealer.reveal_child = true;
	}

	public void remove_animated () {
		selectable = false;
		revealer.notify["child-revealed"].connect (() => {
			get_parent ().remove (this);
		});
		revealer.reveal_child = false;
	}

	[GtkCallback]
	private bool on_draw_image (Cairo.Context cr) {
		var width = image.get_allocated_width ();
		var height = image.get_allocated_height ();

		var style = image.get_style_context ();
		style.render_background (cr, 0.0, 0.0, width, height);
		style.render_frame (cr, 0.0, 0.0, width, height);

		if (pixbuf == null)
			return Gdk.EVENT_PROPAGATE;

		var flags = image.get_state_flags ();
		var border_radius = (int) style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, flags);
		border_radius = border_radius.clamp (0, int.max (width / 2, height / 2));

		rounded_rectangle (cr, 0.5, 0.5, width - 1, height - 1, border_radius);
		cr.clip ();

		cr.save ();
		cr.scale (1.0 / scale_factor, 1.0 / scale_factor);

		var x_offset = (width * scale_factor - pixbuf.width) / 2;
		var y_offset = (height * scale_factor - pixbuf.height) / 2;

		Gdk.cairo_set_source_pixbuf (cr, pixbuf, x_offset, y_offset);
		cr.paint ();

		cr.restore ();

		return Gdk.EVENT_PROPAGATE;
	}

	// TODO: Share this with GameThumbnail
	private void rounded_rectangle (Cairo.Context cr, double x, double y, double width, double height, double radius) {
		const double ARC_0 = 0;
		const double ARC_1 = Math.PI * 0.5;
		const double ARC_2 = Math.PI;
		const double ARC_3 = Math.PI * 1.5;

		cr.new_sub_path ();
		cr.arc (x + width - radius, y + radius,          radius, ARC_3, ARC_0);
		cr.arc (x + width - radius, y + height - radius, radius, ARC_0, ARC_1);
		cr.arc (x + radius,         y + height - radius, radius, ARC_1, ARC_2);
		cr.arc (x + radius,         y + radius,          radius, ARC_2, ARC_3);
		cr.close_path ();
	}

	// Adapted from nautilus-file.c, nautilus_file_get_date_as_string()
	private string get_date_format (DateTime date) {
		var date_midnight = new DateTime.local (date.get_year (),
		                                        date.get_month (),
		                                        date.get_day_of_month (),
		                                        0, 0, 0);
		var now = new DateTime.now ();
		var today_midnight = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
		var days_ago = (today_midnight.difference (date_midnight)) / GLib.TimeSpan.DAY;

		if (days_ago == 0) {
			/* Translators: Time in locale format */
			/* xgettext:no-c-format */
			return _("%X");
		}
		else if (days_ago == 1) {
			/* Translators: this is the word Yesterday followed by
			 * a time in locale format. i.e. "Yesterday 23:04:35" */
			/* xgettext:no-c-format */
			return _("Yesterday %X");
		}
		else if (days_ago > 1 && days_ago < 7) {
			/* Translators: this is the abbreviated name of the week day followed by
			 * a time in locale format. i.e. "Monday 23:04:35" */
			/* xgettext:no-c-format */
			return _("%a %X");
		}
		else if (date.get_year () == now.get_year ()) {
			/* Translators: this is the day of the month followed
			 * by the abbreviated month name followed by a time in
			 * locale format i.e. "3 Feb 23:04:35" */
			/* xgettext:no-c-format */
			return _("%-e %b %X");
		}
		else {
			/* Translators: this is the day number followed
			 * by the abbreviated month name followed by the year followed
			 * by a time in locale format i.e. "3 Feb 2015 23:04:00" */
			/* xgettext:no-c-format */
			return _("%-e %b %Y %X");
		}
	}
}
