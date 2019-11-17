// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.SteamCover : Object, Cover {
	private const string[] URIS = {
		"http://cdn.akamai.steamstatic.com/steam/apps/%s/library_600x900_2x.jpg",
		"http://cdn.akamai.steamstatic.com/steam/apps/%s/library_600x900.jpg",
		"http://cdn.akamai.steamstatic.com/steam/apps/%s/header.jpg"
	};

	private string game_id;
	private File? file;
	private bool resolving;

	public SteamCover (string game_id) {
		this.game_id = game_id;
		resolving = false;
	}

	public File? get_cover () {
		if (resolving)
			return file;

		if (file != null)
			return file;

		load_cover ();
		if (file != null)
			return file;

		resolving = true;

		fetch_covers.begin ();

		return null;
	}

	private string get_cover_path () {
		var dir = Application.get_covers_dir ();

		return @"$dir/steam-$game_id.jpg";
	}

	private async void fetch_covers () {
		foreach (var uri in URIS)
			if (yield fetch_cover (uri.printf (game_id)))
				break;
	}

	private async bool fetch_cover (string uri) {
		var dir = Application.get_covers_dir ();
		Application.try_make_dir (dir);

		var cover_path = get_cover_path ();

		var session = new Soup.Session ();
		var message = new Soup.Message ("GET", uri);
		var success = false;

		session.queue_message (message, (sess, mess) => {
			if (mess.status_code != Soup.Status.OK) {
				debug ("Failed to load %s: %u %s.", uri, mess.status_code, mess.reason_phrase);
				fetch_cover.callback ();
				return;
			}

			try {
				FileUtils.set_data (cover_path, mess.response_body.data);
				load_cover ();
				success = true;
			} catch (Error e) {
				warning (e.message);
			}

			fetch_cover.callback ();
		});
		yield;
		return success;
	}

	private void load_cover () {
		var cover_path = get_cover_path ();

		if (!FileUtils.test (cover_path, FileTest.EXISTS))
			return;

		file = File.new_for_path (cover_path);

		changed ();
	}
}
