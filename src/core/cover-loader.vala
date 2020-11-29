// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CoverLoader : Object {
	const double COVER_BLUR_RADIUS_FACTOR = 30.0 / 128.0;
	const double SHADOW_FACTOR = 20.0 / 128;
	const uint TINY_ICON_SIZE = 32;

	public delegate void CoverReadyCallback (int scale_factor, int cover_size, Gdk.Pixbuf? cover_pixbuf, int icon_size, Gdk.Pixbuf? icon_pixbuf);

	private struct CoverRequest {
		Game game;
		int scale_factor;
		int cover_size;
		int icon_size;
		unowned CoverReadyCallback cb;
	}

	private AsyncQueue<CoverRequest?> request_queue;
	private Thread thread;

	construct {
		request_queue = new AsyncQueue<CoverRequest?> ();
		thread = new Thread<void> (null, run_loader_thread);
	}

	private void run_callback (CoverRequest request, int scale_factor, int cover_size, Gdk.Pixbuf? cover_pixbuf, int icon_size, Gdk.Pixbuf? icon_pixbuf) {
		Idle.add (() => {
			request.cb (scale_factor, cover_size, cover_pixbuf, icon_size, icon_pixbuf);
			return Source.REMOVE;
		});
	}

	private Gdk.Pixbuf? try_load_cover (Game game, int size, int scale_factor) {
		var pixbuf = load_cache_from_disk (game, size, scale_factor, "covers");
		if (pixbuf != null)
			return pixbuf;

		var file = game.get_cover ().get_cover ();

		if (file != null) {
			pixbuf = create_cover_thumbnail (file, size, scale_factor);
			save_cache_to_disk (game, pixbuf, size, scale_factor, "covers");
		}

		return pixbuf;
	}

	private Gdk.Pixbuf? try_load_icon (Game game, int size, int scale_factor) {
		var pixbuf = load_cache_from_disk (game, size, scale_factor, "icons");
		if (pixbuf != null)
			return pixbuf;

		var icon = game.get_icon ().get_icon ();
		if (icon == null)
			return null;

		var theme = Gtk.IconTheme.get_default ();
		var lookup_flags = Gtk.IconLookupFlags.FORCE_SIZE | Gtk.IconLookupFlags.FORCE_REGULAR;
		var icon_info = theme.lookup_by_gicon (icon, (int) size, lookup_flags);

		if (icon_info == null)
			return null;

		try {
			if (icon is Gdk.Pixbuf && ((Gdk.Pixbuf) icon).get_width () <= TINY_ICON_SIZE)
				pixbuf = ((Gdk.Pixbuf) icon).scale_simple (size * scale_factor, size * scale_factor, Gdk.InterpType.NEAREST);
			else
				pixbuf = icon_info.load_icon ();
			save_cache_to_disk (game, pixbuf, size, scale_factor, "icons");
		}
		catch (Error e) {
			critical ("Couldn’t load the icon: %s", e.message);
			return null;
		}

		return pixbuf;
	}

	private void run_loader_thread () {
		while (true) {
			var request = request_queue.pop ();
			var game = request.game;
			var scale_factor = request.scale_factor;
			var cover_size = request.cover_size;
			var icon_size = request.icon_size;

			var cover_pixbuf = try_load_cover (game, cover_size, scale_factor);
			if (cover_pixbuf != null)
				run_callback (request, scale_factor, cover_size, cover_pixbuf, icon_size, null);

			var icon_pixbuf = try_load_icon (game, icon_size, scale_factor);

			run_callback (request, scale_factor,
			              cover_size, cover_pixbuf,
			              icon_size, icon_pixbuf);
		}
	}

	private string get_cache_path (Game game, int size, int scale_factor, string dir_name) {
		var dir = Application.get_image_cache_dir (dir_name, size, scale_factor);

		var uid = game.uid;

		return @"$dir/$uid.png";
	}

	private Gdk.Pixbuf? load_cache_from_disk (Game game, int size, int scale_factor, string dir) {
		var cache_path = get_cache_path (game, size, scale_factor, dir);

		try {
			return new Gdk.Pixbuf.from_file (cache_path);
		}
		catch (Error e) {
			return null;
		}
	}

	private void save_cache_to_disk (Game game, Gdk.Pixbuf pixbuf, int size, int scale_factor, string dir_name) {
		Application.try_make_dir (Application.get_image_cache_dir (dir_name, size, scale_factor));
		var now = new GLib.DateTime.now_local ();
		var creation_time = now.to_string ();

		try {
			var cover_cache_path = get_cache_path (game, size, scale_factor, dir_name);
			pixbuf.save (cover_cache_path, "png",
			            "tEXt::Software", "GNOME Games",
			            "tEXt::Creation Time", creation_time.to_string (),
			            null);
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	private void draw_cover_blur_rect (Cairo.Context cr, Gdk.Pixbuf pixbuf, int size, int scale_factor, bool reverse, int x, int y, int w, int h) {
		int radius = (int) (COVER_BLUR_RADIUS_FACTOR * size);
		int shadow_width = (int) (SHADOW_FACTOR * size);

		if (w == 0 || h == 0)
			return;

		var gradient = new Cairo.Pattern.linear (0, 0,
		                                         h > w ? -shadow_width : 0,
		                                         h < w ? -shadow_width : 0);
		gradient.add_color_stop_rgba (0, 0, 0, 0, 0.15);
		gradient.add_color_stop_rgba (1, 0, 0, 0, 0);

		cr.save ();

		cr.rectangle (0, 0, w, h);
		cr.clip ();

		var subpixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, x, y, w, h);
		var surface = Gdk.cairo_surface_create_from_pixbuf (subpixbuf, 0, null);
		CairoBlur.blur_surface (surface, radius);
		cr.set_source_surface (surface, 0, 0);
		cr.paint ();

		if (reverse)
			cr.rotate (Math.PI);
		else if (h > w)
			cr.translate (w, 0);
		else
			cr.translate (0, h);

		cr.set_source (gradient);
		cr.paint ();

		cr.rotate (Math.PI);

		if (h > w)
			cr.rectangle (0, reverse ? 0 : -h, scale_factor, h);
		else
			cr.rectangle (reverse ? 0 : -w, 0, w, scale_factor);

		cr.set_source_rgba (0, 0, 0, 0.2);
		cr.fill ();

		cr.set_source_rgba (0, 0, 0, 0.1);
		cr.paint ();

		cr.restore ();
	}

	private Gdk.Pixbuf? create_cover_thumbnail (File file, int size, int scale_factor) {
		Gdk.Pixbuf overlay_pixbuf, blur_pixbuf;
		int overlay_x, overlay_y;
		int width, height, zoom_width, zoom_height;
		double aspect_ratio;

		Gdk.Pixbuf.get_file_info (file.get_path (), out width, out height);

		aspect_ratio = (double) width / height;

		if (height >= width) {
			height = size;
			width = (int) (size * aspect_ratio);

			zoom_width = size;
			zoom_height = (int) (size * height / (double) width);

			overlay_x = (int) ((height - width) / 2);
			overlay_y = 0;
		}
		else {
			width = size;
			height = (int) (size / aspect_ratio);

			zoom_height = size;
			zoom_width = (int) (size * width / (double) height);

			overlay_x = 0;
			overlay_y = (int) ((width - height) / 2);
		}

		if (width == height) {
			try {
				return new Gdk.Pixbuf.from_file_at_scale (file.get_path (), width, height, false);
			}
			catch (Error e) {
				critical ("Failed to load cover: %s", e.message);
			}
		}

		var image_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, size, size);
		var cr = new Cairo.Context (image_surface);

		try {
			overlay_pixbuf = new Gdk.Pixbuf.from_file_at_scale (file.get_path (), width, height, false);
			blur_pixbuf = new Gdk.Pixbuf.from_file_at_scale (file.get_path (), zoom_width, zoom_height, false);
		}
		catch (Error e) {
			critical ("Failed to load cover image: %s", e.message);
			return null;
		}

		cr.save ();

		if (height >= width) {
			var blur_y = (int) ((double) (height - width) / 2);

			draw_cover_blur_rect (cr, blur_pixbuf, size, scale_factor, false,
			                      0, blur_y, overlay_x, size);

			if (height > width)
				cr.translate (overlay_x + width, 0);
			else
				cr.translate (0, blur_y);

			draw_cover_blur_rect (cr, blur_pixbuf, size, scale_factor, true,
			                      overlay_x + width, blur_y,
			                      size - width - overlay_x, size);
		}
		else {
			var blur_x = (int) ((double) (width - height) / 2);

			draw_cover_blur_rect (cr, blur_pixbuf, size, scale_factor, false,
			                      blur_x, 0, size, overlay_y);

			if (height > width)
				cr.translate (blur_x, 0);
			else
				cr.translate (0, overlay_y + height);

			draw_cover_blur_rect (cr, blur_pixbuf, size, scale_factor, true,
			                      blur_x, overlay_y + height,
			                      size, size - height - overlay_y);
		}

		cr.restore ();

		Gdk.cairo_set_source_pixbuf (cr, overlay_pixbuf, overlay_x, overlay_y);
		cr.paint ();

		return Gdk.pixbuf_get_from_surface (image_surface, 0, 0, size, size);
	}

	public void fetch_cover (Game game, int scale_factor, int cover_size, int icon_size, CoverReadyCallback cb) {
		request_queue.push ({ game, scale_factor, cover_size, icon_size, cb });
	}
}
