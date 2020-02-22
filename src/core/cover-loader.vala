// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CoverLoader : Object {
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

	private void get_dimensions (File file, int size, out int width, out int height) {
		int w, h;
		Gdk.Pixbuf.get_file_info (file.get_path (), out w, out h);

		double aspect_ratio = (double) w / h;

		width = w;
		height = (int) (w / aspect_ratio);

		if (width > h) {
			width = size;
			height = (int) (size / aspect_ratio);
		}
		else {
			height = size;
			width = (int) (size * aspect_ratio);
		}
	}

	private Gdk.Pixbuf? try_load_cover (Game game, int size) {
		var pixbuf = load_cache_from_disk (game, size, "covers");
		if (pixbuf != null)
			return pixbuf;

		var file = game.get_cover ().get_cover ();

		if (file != null) {
			int width, height;
			get_dimensions (file, size, out width, out height);

			try {
				pixbuf = new Gdk.Pixbuf.from_file_at_scale (file.get_path (), width, height, false);
				save_cache_to_disk (game, pixbuf, size, "covers");
			}
			catch (Error e) {
				return null;
			}
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

	private string get_cache_path (Game game, int size, string dir_name) throws Error {
		var dir = Application.get_image_cache_dir (dir_name, size);

		var uid = game.get_uid ().get_uid ();

		return @"$dir/$uid.png";
	}

	private Gdk.Pixbuf? load_cache_from_disk (Game game, int size, string dir) {
		string cache_path;
		try {
			cache_path = get_cache_path (game, size, dir);
		}
		catch (Error e) {
			critical (e.message);
			return null;
		}

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

	public void fetch_cover (Game game, int cover_size, int icon_size, CoverReadyCallback cb) {
		request_queue.push ({ game, cover_size, icon_size, cb });
	}
}
