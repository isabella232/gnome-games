// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CoverLoader : Object {
	const double COVER_BLUR_RADIUS_FACTOR = 30.0 / 128.0;

	public delegate void CoverReadyCallback (int cover_size, Gdk.Pixbuf? cover_pixbuf, int icon_size, Gdk.Pixbuf? icon_pixbuf);

	private struct CoverRequest {
		Game game;
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

	private void run_callback (CoverRequest request, int cover_size, Gdk.Pixbuf? cover_pixbuf, int icon_size, Gdk.Pixbuf? icon_pixbuf) {
		Idle.add (() => {
			request.cb (cover_size, cover_pixbuf, icon_size, icon_pixbuf);
			return Source.REMOVE;
		});
	}

	private Gdk.Pixbuf? try_load_cover (Game game, int size) {
		var pixbuf = load_cache_from_disk (game, size, "covers");
		if (pixbuf != null)
			return pixbuf;

		var file = game.get_cover ().get_cover ();

		if (file != null) {
			pixbuf = create_cover_thumbnail (file, size);
			save_cache_to_disk (game, pixbuf, size, "covers");
		}

		return pixbuf;
	}

	private Gdk.Pixbuf? try_load_icon (Game game, int size) {
		var pixbuf = load_cache_from_disk (game, size, "icons");
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
			pixbuf = icon_info.load_icon ();
			save_cache_to_disk (game, pixbuf, size, "icons");
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
			var cover_size = request.cover_size;
			var icon_size = request.icon_size;

			var cover_pixbuf = try_load_cover (game, cover_size);
			if (cover_pixbuf != null)
				run_callback (request, cover_size, cover_pixbuf, icon_size, null);

			var icon_pixbuf = try_load_icon (game, icon_size);

			run_callback (request, cover_size, cover_pixbuf, icon_size, icon_pixbuf);
		}
	}

	private string get_cache_path (Game game, int size, string dir_name) {
		var dir = Application.get_image_cache_dir (dir_name, size);

		var uid = game.uid;

		return @"$dir/$uid.png";
	}

	private Gdk.Pixbuf? load_cache_from_disk (Game game, int size, string dir) {
		var cache_path = get_cache_path (game, size, dir);

		try {
			return new Gdk.Pixbuf.from_file (cache_path);
		}
		catch (Error e) {
			return null;
		}
	}

	private void save_cache_to_disk (Game game, Gdk.Pixbuf pixbuf, int size, string dir_name) {
		Application.try_make_dir (Application.get_image_cache_dir (dir_name, size));
		var now = new GLib.DateTime.now_local ();
		var creation_time = now.to_string ();

		try {
			var cover_cache_path = get_cache_path (game, size, dir_name);
			pixbuf.save (cover_cache_path, "png",
			            "tEXt::Software", "GNOME Games",
			            "tEXt::Creation Time", creation_time.to_string (),
			            null);
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	private Gdk.Pixbuf? create_cover_thumbnail (File file, int size) {
		Gdk.Pixbuf overlay_pixbuf, blur_pixbuf;
		int blur_x, blur_y, overlay_x, overlay_y;
		int width, height, radius;
		double aspect_ratio;

		radius = (int) (COVER_BLUR_RADIUS_FACTOR * size);
		Gdk.Pixbuf.get_file_info (file.get_path (), out width, out height);
		aspect_ratio = (double) width / height;

		if (height >= width) {
			height = size;
			width = (int) (size * aspect_ratio);
			aspect_ratio = (double) width / height;

			blur_x = 0;
			blur_y = (int) (height * (1 - aspect_ratio) / 2);

			overlay_x = (int) ((width/aspect_ratio - width) / 2);
			overlay_y = 0;
		}
		else {
			width = size;
			height = (int) (size / aspect_ratio);
			aspect_ratio = (double) height / width;

			blur_x = (int) (width * (1 - aspect_ratio) / 2);
			blur_y = 0;

			overlay_x = 0;
			overlay_y = (int) ((height/aspect_ratio - height) / 2);
		}

		var zoom_width = (int) (width / aspect_ratio);
		var zoom_height = (int) (height / aspect_ratio);

		var image_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, size, size);
		var target_cr = new Cairo.Context (image_surface);

		try {
			overlay_pixbuf = new Gdk.Pixbuf.from_file_at_scale (file.get_path (), width, height, false);
			var temp_pixbuf = new Gdk.Pixbuf.from_file_at_scale (file.get_path (), zoom_width, zoom_height, false);
			blur_pixbuf = new Gdk.Pixbuf.subpixbuf (temp_pixbuf, blur_x, blur_y, size, size);
		}
		catch (Error e) {
			critical ("Failed to load cover image: %s", e.message);
			return null;
		}

		var surface = Gdk.cairo_surface_create_from_pixbuf (blur_pixbuf, 0, null);
		var shadow_cr = new Cairo.Context (surface);
		shadow_cr.rectangle (overlay_x, overlay_y, width, height);
		shadow_cr.set_source_rgba (0, 0, 0, 0.2);
		shadow_cr.fill ();

		shadow_cr.set_source_rgba (0, 0, 0, 0.1);
		shadow_cr.paint ();

		CairoBlur.blur_surface (surface, radius);
		target_cr.set_source_surface (surface, 0, 0);
		target_cr.paint ();

		target_cr.rectangle (overlay_x - 1, overlay_y - 1, width + 2, height + 2);
		target_cr.set_source_rgba (0, 0, 0, 0.2);
		target_cr.fill ();

		Gdk.cairo_set_source_pixbuf (target_cr, overlay_pixbuf, overlay_x, overlay_y);
		target_cr.paint ();

		return Gdk.pixbuf_get_from_surface (image_surface, 0, 0, size, size);
	}

	public void fetch_cover (Game game, int cover_size, int icon_size, CoverReadyCallback cb) {
		request_queue.push ({ game, cover_size, icon_size, cb });
	}
}
