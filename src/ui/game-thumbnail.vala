// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameThumbnail : Gtk.DrawingArea {
	private const double EMBLEM_SCALE = 0.125;
	private const double ICON_SCALE = 0.75;

	private ulong cover_changed_id;
	private Icon icon;
	private Cover cover;

	private Game _game;
	public Game game {
		get { return _game; }
		set {
			if (_game == value)
				return;

			if (cover != null)
				cover.disconnect (cover_changed_id);

			_game = value;
			icon = game.get_icon ();
			cover = game.get_cover ();

			try_load_cover = true;

			if (cover != null)
				cover_changed_id = cover.changed.connect (() => {
					try_load_cover = true;
					queue_draw ();
				});

			queue_draw ();
		}
	}

	private Gdk.Pixbuf? cover_pixbuf;
	private Gdk.Pixbuf? icon_pixbuf;
	private bool try_load_cover;
	private int last_cover_size;

	public struct DrawingContext {
		Cairo.Context cr;
		Gtk.StyleContext style;
		Gtk.StateFlags state;
		int width;
		int height;
	}

	construct {
		try_load_cover = true;
	}

	static construct {
		set_css_name ("gamesgamethumbnail");
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
	}

	public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
		minimum_height = natural_height = width;
	}

	public override bool draw (Cairo.Context cr) {
		var style = get_style_context ();
		var state = get_state_flags ();
		var width = get_allocated_width ();
		var height = get_allocated_height ();

		DrawingContext context = {
			cr, style, state, width, height
		};

		if (icon == null)
			return false;

		if (cover == null)
			return false;

		context.style.render_background (cr, 0.0, 0.0, width, height);
		context.style.render_frame (cr, 0.0, 0.0, width, height);

		draw_image (context);

		return true;
	}

	private void update_style_classes () {
		if (cover_pixbuf != null)
			get_style_context ().add_class ("cover");
		else
			get_style_context ().remove_class ("cover");

		if (icon_pixbuf != null && cover_pixbuf == null)
			get_style_context ().add_class ("icon");
		else
			get_style_context ().remove_class ("icon");
	}

	public void draw_image (DrawingContext context) {
		Gdk.Pixbuf cover, icon;
		get_icon_and_cover (context, out cover, out icon);

		if (cover != null) {
			draw_pixbuf (context, cover);

			return;
		}

		if (icon != null) {
			draw_pixbuf (context, icon);

			return;
		}

		var emblem = get_emblem (context);

		if (emblem != null)
			draw_pixbuf (context, emblem);
	}

	private Gdk.Pixbuf? get_emblem (DrawingContext context) {
		string icon_name = @"$(Config.APPLICATION_ID)-symbolic";
		Gdk.Pixbuf? emblem = null;

		var color = context.style.get_color (context.state);

		var theme = Gtk.IconTheme.get_default ();
		var size = int.min (context.width, context.height) * EMBLEM_SCALE * scale_factor;
		try {
			var icon_info = theme.lookup_icon (icon_name, (int) size, Gtk.IconLookupFlags.FORCE_SIZE);
			emblem = icon_info.load_symbolic (color);
		}
		catch (GLib.Error error) {
			warning (@"Unable to get icon “$icon_name”: $(error.message)");
		}

		return emblem;
	}

	private void get_icon_and_cover (DrawingContext context, out Gdk.Pixbuf cover, out Gdk.Pixbuf icon) {
		var cover_size = int.min (context.width, context.height) * scale_factor;
		var icon_size = (int) (cover_size * ICON_SCALE);

		if (cover_size != last_cover_size) {
			cover_pixbuf = null;
			icon_pixbuf = null;
			update_style_classes ();
			try_load_cover = true;
		}

		if (!try_load_cover) {
			cover = cover_pixbuf;
			icon = icon_pixbuf;
			return;
		}

		var loader = Application.get_default ().get_cover_loader ();

		last_cover_size = cover_size;

		try_load_cover = false;
		loader.fetch_cover (game, cover_size, icon_size, (cover_size, cover_pixbuf, icon_size, icon_pixbuf) => {
			if (cover_size != last_cover_size) {
				this.cover_pixbuf = null;
				this.icon_pixbuf = null;

				try_load_cover = true;
			}
			else {
				if (cover_pixbuf != null)
					this.cover_pixbuf = cover_pixbuf;

				if (icon_pixbuf != null)
					this.icon_pixbuf = icon_pixbuf;
			}

			update_style_classes ();

			queue_draw ();
		});

		cover = cover_pixbuf;
		icon = icon_pixbuf;
	}

	private void draw_pixbuf (DrawingContext context, Gdk.Pixbuf pixbuf) {
		context.cr.save ();
		context.cr.scale (1.0 / scale_factor, 1.0 / scale_factor);

		var mask = get_mask (context);

		var x_offset = (context.width * scale_factor - pixbuf.width) / 2;
		var y_offset = (context.height * scale_factor - pixbuf.height) / 2;

		Gdk.cairo_set_source_pixbuf (context.cr, pixbuf, x_offset, y_offset);
		context.cr.mask_surface (mask, 0, 0);

		context.cr.restore ();
	}

	private Cairo.Surface get_mask (DrawingContext context) {
		var mask = new Cairo.ImageSurface (Cairo.Format.A8, context.width * scale_factor, context.height * scale_factor);

		var border_radius = (int) context.style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, context.state);
		border_radius = border_radius.clamp (0, int.max (context.width / 2, context.height / 2));

		var cr = new Cairo.Context (mask);
		cr.scale (scale_factor, scale_factor);
		cr.set_source_rgb (0, 0, 0);
		rounded_rectangle (cr, 0.5, 0.5, context.width - 1, context.height - 1, border_radius);
		cr.fill ();

		return mask;
	}

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
