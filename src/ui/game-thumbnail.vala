// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GameThumbnail: Gtk.DrawingArea {
	private const double EMBLEM_SCALE = 0.125;
	private const double ICON_SCALE = 0.75;

	private Uid _uid;
	public Uid uid {
		get { return _uid; }
		set {
			if (_uid == value)
				return;

			_uid = value;

			icon_cache = null;
			invalidate_cover ();
		}
	}

	private Icon _icon;
	public Icon icon {
		get { return _icon; }
		set {
			if (_icon == value)
				return;

			_icon = value;

			icon_cache = null;
			queue_draw ();
		}
	}

	private Cover _cover;
	public Cover cover {
		get { return _cover; }
		set {
			if (_cover == value)
				return;

			_cover = value;

			invalidate_cover ();
		}
	}

	private bool tried_loading_cover;
	private Gdk.Pixbuf? icon_cache;
	private Gdk.Pixbuf? cover_cache;
	private int cache_width;
	private int cache_height;

	public struct DrawingContext {
		Cairo.Context cr;
		Gdk.Window? window;
		Gtk.StyleContext style;
		Gtk.StateFlags state;
		int width;
		int height;
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
		var window = get_window ();
		var style = get_style_context ();
		var state = get_state_flags ();
		var width = get_allocated_width ();
		var height = get_allocated_height ();

		DrawingContext context = {
			cr, window, style, state, width, height
		};

		if (cache_height != context.height || cache_width != context.width) {
			cache_height = context.height;
			cache_width = context.width;
			icon_cache = null;
			cover_cache = null;
			tried_loading_cover = false;
		}

		load_cache.begin (context.width, context.height);

		draw_border (context);
		if (cover_cache != null)
			draw_black_background (context);
		else
			draw_background (context);

		var thumbnail = cover_cache ?? icon_cache ?? get_emblem (context);
		if (thumbnail != null)
			draw_pixbuf (context, thumbnail);

		return true;
	}

	private async void load_cache (int width, int height) {
		if (cover_cache == null && icon_cache == null) {
			var cache = yield get_cover_cache (width, height);
			if (width == cache_width && height == cache_height)
				cover_cache = cache;
		}
		if (cover_cache == null && icon_cache == null) {
			var cache = yield get_icon_cache (width, height);
			if (width == cache_width && height == cache_height)
				icon_cache = cache;
		}

		queue_draw ();
	}

	private Gdk.Pixbuf? get_emblem (DrawingContext context) {
		var color = context.style.get_color (context.state);
		var theme = Gtk.IconTheme.get_default ();
		var size = int.min (context.width, context.height) * EMBLEM_SCALE;
		var icon_info = theme.lookup_icon ("applications-games-symbolic", (int) size,
		                                   Gtk.IconLookupFlags.FORCE_SIZE);

		if (icon_info == null) {
			warning ("Couldn't find the emblem");
			return null;
		}
		try {
			return icon_info.load_symbolic (color);
		} catch (Error e) {
			warning (@"Couldn’t load the emblem: $(e.message)");
			return null;
		}
	}

	private async Gdk.Pixbuf? get_icon_cache (int width, int height) {
		if (icon == null)
			return null;

		var g_icon = icon.get_icon ();
		if (g_icon == null)
			return null;

		var theme = Gtk.IconTheme.get_default ();
		var lookup_flags = Gtk.IconLookupFlags.FORCE_SIZE | Gtk.IconLookupFlags.FORCE_REGULAR;
		var size = int.min (width, height) * ICON_SCALE;
		var icon_info = theme.lookup_by_gicon (g_icon, (int) size, lookup_flags);

		if (icon_info == null) {
			warning ("Couldn't find the icon");
			return null;
		}
		try {
			return yield icon_info.load_icon_async ();
		}
		catch (Error e) {
			warning (@"Couldn’t load the icon: $(e.message)");
			return null;
		}
	}

	private async Gdk.Pixbuf? get_cover_cache (int width, int height) {
		var cover_cache = load_cover_cache_from_disk (width, height);
		if (cover_cache != null)
			return cover_cache;

		if (cover == null)
			return null;

		var g_icon = yield cover.get_cover ();
		if (g_icon == null)
			return null;

		var theme = Gtk.IconTheme.get_default ();
		var lookup_flags = Gtk.IconLookupFlags.FORCE_SIZE | Gtk.IconLookupFlags.FORCE_REGULAR;
		var size = int.min (width, height);
		var icon_info = theme.lookup_by_gicon (g_icon, (int) size, lookup_flags);

		if (icon_info == null) {
			warning ("Couldn't find the cover");
			return null;
		}
		try {
			cover_cache = yield icon_info.load_icon_async ();
			save_cover_cache_to_disk (cover_cache, size);
		}
		catch (Error e) {
			warning (@"Couldn’t load the cover: $(e.message)");
		}

		return cover_cache;
	}

	private Gdk.Pixbuf? load_cover_cache_from_disk (int width, int height) {
		if (tried_loading_cover)
			return null;

		tried_loading_cover = true;

		var size = int.min (width, height);
		string cover_cache_path;
		try {
			cover_cache_path = get_cover_cache_path (size);
		}
		catch (Error e) {
			critical (e.message);
			return null;
		}

		try {
			return new Gdk.Pixbuf.from_file_at_scale (cover_cache_path, width, height, true);
		}
		catch (Error e) {
			debug (e.message);
			return null;
		}
	}

	private void save_cover_cache_to_disk (Gdk.Pixbuf? cover_cache, int size) {
		if (cover_cache == null)
			return;

		Application.try_make_dir (Application.get_covers_cache_dir (size));
		var now = new DateTime.now_local ();

		try {
			var cover_cache_path = get_cover_cache_path (size);
			cover_cache.save (cover_cache_path, "png",
			                  "tEXt::Software", "GNOME Games",
			                  "tEXt::Creation Time", now.to_string (),
			                  null);
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	private string get_cover_cache_path (int size) throws Error {
		var dir = Application.get_covers_cache_dir (size);
		var uid = uid.get_uid ();

		return @"$dir/$uid.png";
	}

	private void invalidate_cover () {
		cover_cache = null;
		tried_loading_cover = false;
		queue_draw ();
	}

	private void draw_pixbuf (DrawingContext context, Gdk.Pixbuf pixbuf) {
		var surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, context.window);

		var mask = get_mask (context);

		var x_offset = (context.width - pixbuf.width) / 2;
		var y_offset = (context.height - pixbuf.height) / 2;

		context.cr.set_source_surface (surface, x_offset, y_offset);
		context.cr.mask_surface (mask, 0, 0);
	}

	private Cairo.Surface get_mask (DrawingContext context) {
		Cairo.ImageSurface mask = new Cairo.ImageSurface (Cairo.Format.A8, context.width, context.height);

		var border_radius = (int) context.style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, context.state);

		Cairo.Context cr = new Cairo.Context (mask);
		cr.set_source_rgba (0, 0, 0, 0.9);
		rounded_rectangle (cr, 0.5, 0.5, context.width - 1, context.height - 1, border_radius);
		cr.fill ();

		return mask;
	}

	private void draw_black_background (DrawingContext context) {
		var border_radius = (int) context.style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, context.state);
		context.cr.set_source_rgb (0, 0, 0);
		rounded_rectangle (context.cr, 0.5, 0.5, context.width - 1, context.height - 1, border_radius);
		context.cr.fill ();
	}

	private void draw_background (DrawingContext context) {
		context.style.render_background (context.cr, 0.0, 0.0, context.width, context.height);
	}

	private void draw_border (DrawingContext context) {
		context.style.render_frame (context.cr, 0.0, 0.0, context.width, context.height);
	}

	private void rounded_rectangle (Cairo.Context cr, double x, double y, double width, double height, double radius) {
		const double ARC_0 = 0;
		const double ARC_1 = Math.PI * 0.5;
		const double ARC_2 = Math.PI;
		const double ARC_3 = Math.PI * 1.5;

		cr.new_sub_path ();
		cr.arc (x + width - radius, y + radius,	         radius, ARC_3, ARC_0);
		cr.arc (x + width - radius, y + height - radius, radius, ARC_0, ARC_1);
		cr.arc (x + radius,         y + height - radius, radius, ARC_1, ARC_2);
		cr.arc (x + radius,         y + radius,          radius, ARC_2, ARC_3);
		cr.close_path ();
	}
}
