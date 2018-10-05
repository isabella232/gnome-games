// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.SteamCover : Object, Cover {
	private string game_id;
	private GLib.Icon icon;

	public SteamCover (string game_id) {
		this.game_id = game_id;
	}

	public async GLib.Icon? get_cover () {
		if (icon != null)
			return icon;

		load_cover ();
		if (icon != null)
			return icon;

		var uri = @"http://cdn.akamai.steamstatic.com/steam/apps/$game_id/header.jpg";
		yield fetch_cover (uri);
		load_cover ();

		return icon;
	}

	private string get_cover_path () {
		var dir = Application.get_covers_dir ();

		return @"$dir/steam-$game_id.jpg";
	}

	private async void fetch_cover (string uri) {
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
			Idle.add (fetch_cover.callback);
		});

		yield;
	}

	private void load_cover () {
		var cover_path = get_cover_path ();

		if (!FileUtils.test (cover_path, FileTest.EXISTS))
			return;

		var file = File.new_for_path (cover_path);
		icon = new FileIcon (file);
	}
}
