// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloCover : Object, Cover {
	private GriloMedia media;
	private Uid uid;
	private File? file;
	private string cover_path;

	public GriloCover (GriloMedia media, Uid uid) {
		this.media = media;
		this.uid = uid;
		media.resolved.connect (on_media_resolved);
	}

	public GLib.File? get_cover () {
		if (file != null)
			return file;

		try {
			load_cover ();
		}
		catch (Error e) {
			warning (e.message);

			return file;
		}

		if (file != null)
			return file;

		media.try_resolve_media ();

		return file;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		if (grl_media.length (Grl.MetadataKey.THUMBNAIL) == 0)
			return;

		var uri = grl_media.get_thumbnail_nth (0);
		try_fetch_cover.begin (uri);
	}

	private string get_cover_path () throws Error {
		if (cover_path != null)
			return cover_path;

		var dir = Application.get_covers_dir ();
		cover_path = @"$dir/$uid.cover";

		return cover_path;
	}

	private async void try_fetch_cover (string uri) {
		try {
			yield fetch_cover (uri);
		}
		catch (Error e) {
			warning (e.message);

			return;
		}
	}

	private async void fetch_cover (string uri) throws Error {
		var dir = Application.get_covers_dir ();
		Application.try_make_dir (dir);

		var cover_path = get_cover_path ();

		var session = new Soup.Session ();
		var message = new Soup.Message ("GET", uri);

		session.queue_message (message, (sess, mess) => {
			if (mess.status_code != Soup.Status.OK) {
				debug ("Failed to load %s: %u %s.", uri, mess.status_code, mess.reason_phrase);

				return;
			}

			try {
				FileUtils.set_data (cover_path, mess.response_body.data);
				load_cover ();
			} catch (Error e) {
				warning (e.message);
			}
		});
	}

	private void load_cover () throws Error {
		var cover_path = get_cover_path ();

		if (!FileUtils.test (cover_path, FileTest.EXISTS))
			return;

		file = File.new_for_path (cover_path);

		changed ();
	}
}
