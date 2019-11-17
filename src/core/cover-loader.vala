// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CoverLoader : Object {
	public delegate void CoverReadyCallback (int size, Gdk.Pixbuf? pixbuf);

	private struct CoverRequest {
		Game game;
		int size;
		unowned CoverReadyCallback cb;
	}

	private AsyncQueue<CoverRequest?> request_queue;
	private Thread thread;

	construct {
		request_queue = new AsyncQueue<CoverRequest?> ();
		thread = new Thread<void> (null, run_loader_thread);
	}

	private void run_callback (CoverRequest request, int size, Gdk.Pixbuf? pixbuf) {
		Idle.add (() => {
			request.cb (size, pixbuf);
			return Source.REMOVE;
		});
	}

	private void run_loader_thread () {
		while (true) {
			var request = request_queue.pop ();
			var game = request.game;
			var size = request.size;

			var pixbuf = load_cover_cache_from_disk (game, size);
			if (pixbuf != null) {
				run_callback (request, size, pixbuf);
				continue;
			}

			var g_icon = game.get_cover ().get_cover ();
			if (g_icon == null) {
				run_callback (request, size, null);
				continue;
			}

			var theme = Gtk.IconTheme.get_default ();
			var lookup_flags = Gtk.IconLookupFlags.FORCE_SIZE | Gtk.IconLookupFlags.FORCE_REGULAR;
			var icon_info = theme.lookup_by_gicon (g_icon, (int) size, lookup_flags);

			try {
				pixbuf = icon_info.load_icon ();
				save_cover_cache_to_disk (game, pixbuf, size);
			}
			catch (Error e) {
				run_callback (request, size, null);
				continue;
			}

			run_callback (request, size, pixbuf);
		}
	}

	private string get_cover_cache_path (Game game, int size) throws Error {
		var dir = Application.get_covers_cache_dir (size);

		var uid = game.get_uid ().get_uid ();

		return @"$dir/$uid.png";
	}

	private Gdk.Pixbuf? load_cover_cache_from_disk (Game game, int size) {
		string cover_cache_path;
		try {
			cover_cache_path = get_cover_cache_path (game, size);
		}
		catch (Error e) {
			critical (e.message);
			return null;
		}

		try {
			return new Gdk.Pixbuf.from_file (cover_cache_path);
		}
		catch (Error e) {
			return null;
		}
	}

	private void save_cover_cache_to_disk (Game game, Gdk.Pixbuf pixbuf, int size) {
		Application.try_make_dir (Application.get_covers_cache_dir (size));
		var now = new GLib.DateTime.now_local ();
		var creation_time = now.to_string ();

		try {
			var cover_cache_path = get_cover_cache_path (game, size);
			pixbuf.save (cover_cache_path, "png",
			            "tEXt::Software", "GNOME Games",
			            "tEXt::Creation Time", creation_time.to_string (),
			            null);
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void fetch_cover (Game game, int size, CoverReadyCallback cb) {
		request_queue.push ({ game, size, cb });
	}
}
