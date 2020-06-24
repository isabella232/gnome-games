// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SnapshotThumbnail : Gtk.DrawingArea {
	public const int THUMBNAIL_SIZE = 64;

	private Snapshot _snapshot;
	public Snapshot snapshot {
		get { return _snapshot; }
		set {
			_snapshot = value;

			load_thumbnail ();
		}
	}

	private Gdk.Pixbuf pixbuf;

	construct {
		width_request = THUMBNAIL_SIZE;
		height_request = THUMBNAIL_SIZE;

		get_style_context ().add_class ("snapshot-thumbnail");

		notify["scale-factor"].connect (load_thumbnail);
	}

	private void load_thumbnail () {
		if (snapshot == null)
			return;

		var screenshot_path = snapshot.get_screenshot_path ();
		var screenshot_width = 0;
		var screenshot_height = 0;

		Gdk.Pixbuf.get_file_info (screenshot_path, out screenshot_width, out screenshot_height);

		var aspect_ratio = snapshot.screenshot_aspect_ratio;

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

	public override void size_allocate (Gtk.Allocation alloc) {
		var context = get_style_context ();
		var clip = context.render_background_get_clip (
			alloc.x,
			alloc.y,
			alloc.width,
			alloc.height
		);

		base.size_allocate (alloc);

		set_clip (clip);
	}

	public override bool draw (Cairo.Context cr) {
		var width = get_allocated_width ();
		var height = get_allocated_height ();

		var style = get_style_context ();
		style.render_background (cr, 0.0, 0.0, width, height);
		style.render_frame (cr, 0.0, 0.0, width, height);

		if (pixbuf == null)
			return Gdk.EVENT_PROPAGATE;

		cr.save ();

		var flags = get_state_flags ();
		var border_radius = (int) style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, flags);
		border_radius = border_radius.clamp (0, int.max (width / 2, height / 2));

		rounded_rectangle (cr, 0, 0, width, height, border_radius);
		cr.clip ();

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
}
