// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.SharpX68000GameFactory : Object, UriGameFactory {
	private const string FINGERPRINT_PREFIX = "sharp-x68000";
	private const string MIME_TYPE_DIM = "application/x-x68k-rom";
	private const string MIME_TYPE_XDF = "application/x-x68k-xdf-rom";
	private const string MIME_TYPE_HDF = "application/x-x68k-hdf-rom";
	private const string MIME_TYPE_TGDB = "application/x-sharp-x68000-rom";
	private const string PLATFORM = "SharpX68000";
	private const string ICON_NAME = "media-floppy-symbolic";

	private HashTable<string, PartialGameData?> uris_for_game;
	private HashTable<Uri, Game> game_for_uri;
	private GenericSet<Game> games;
	private RetroPlatform platform;
	private unowned GameCallback game_added_callback;

	private struct PartialGameData {
		Uri?[] uris;
		string?[] titles;
	}

	public SharpX68000GameFactory (RetroPlatform platform) {
		uris_for_game = new HashTable<string, PartialGameData?> (str_hash, str_equal);
		game_for_uri = new HashTable<Uri, Game> (Uri.hash, Uri.equal);
		games = new GenericSet<Game> (direct_hash, direct_equal);
		this.platform = platform;
	}

	public string[] get_mime_types () {
		return { MIME_TYPE_DIM, MIME_TYPE_XDF, MIME_TYPE_HDF };
	}

	public Game? query_game_for_uri (Uri uri) {
		if (game_for_uri.contains (uri))
			return game_for_uri[uri];

		return null;
	}

	public void add_uri (Uri uri) {
		try {
			add_uri_with_error (uri);
		}
		catch (Error e) {
			debug (e.message);
		}
	}

	private void add_uri_with_error (Uri uri) throws Error {
		if (game_for_uri.contains (uri))
			return;

		var file = uri.to_file ();
		var file_info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE);
		var mime_type = file_info.get_content_type ();

		if (mime_type != MIME_TYPE_DIM && mime_type != MIME_TYPE_XDF && mime_type != MIME_TYPE_HDF)
			return;

		var path = file.get_path ();
		print ("%s\n", path);

		var regex = /\((Dis[ck] (\d+)) of (\d+)\)/i;
		MatchInfo match_info;
		if (regex.match (path, 0, out match_info)) {
			// The game has multiple disks
			var title = match_info.fetch (1);
			var index = int.parse (match_info.fetch (2));
			var total = int.parse (match_info.fetch (3));
			print ("%d %d\n", index, total);

			if (index > 0 && total > 0) {
				var game_id = regex.replace (path, path.length, 0, "");
				print ("%s\n", game_id);
				if (!uris_for_game.contains (game_id))
					uris_for_game.insert(game_id, { new Uri?[total], new string?[total] });
				uris_for_game.lookup(game_id).uris[index - 1] = uri;
				uris_for_game.lookup(game_id).titles[index - 1] = title;

				var data = uris_for_game.lookup(game_id);
				bool complete = true;
				foreach (var u in data.uris)
					if (u == null) {
						complete = false;
						print ("null\n");
					} else
						print ("%s\n", u.to_string());
				print ("%d\n", complete ? 1 : 0);

				if (complete) {
					var media_set = new MediaSet ();
					for (var i = 0; i < total; i++) {
						var media = new Media (new GenericTitle (data.titles[i]));
						media.add_uri (data.uris[i]);
						media_set.add_media (media);
					}
					media_set.icon_name = ICON_NAME;

					var game = create_game (media_set, data.uris[0], mime_type);

					foreach (var u in data.uris)
						game_for_uri[u] = game;

					games.add (game);
					if (game_added_callback != null)
						game_added_callback (game);
				}

				return;
			}
		}

		print ("The game is single-disk\n");

		var game = create_game (null, uri, mime_type);

		game_for_uri[uri] = game;
		games.add (game);

		if (game_added_callback != null)
			game_added_callback (game);
/*
//		File bin_file;
//		var disc_id = uri.to_string

		// Check whether we already have a media and by extension a media set
		// and a game for this disc ID. If such a case, simply add the new URI.
		if (media_for_disc_id.contains (disc_id)) {
			var media = media_for_disc_id.lookup (disc_id);
			media.add_uri (uri);
			game_for_uri[uri] = game_for_disc_set_id[disc_set_id];

			return;
		}
/*
		var media_set = new MediaSet ();
		foreach (var game_media in new_medias_array)
			media_set.add_media (game_media);
		media_set.icon = GLib.Icon.new_for_string (ICON_NAME);
		var game = create_game (media_set, disc_set_id, uri);

		// Creating the Medias, MediaSet and Game worked, we can save them.

		foreach (var new_disc_id in new_medias.get_keys ())
			media_for_disc_id[new_disc_id] = new_medias[new_disc_id];
*/

//		var game = create_game (uri);

//		game_for_uri[uri] = game;
//		games.add (game);

//		game_added (game);
	}

	public void foreach_game (GameCallback game_callback) {
		games.foreach ((game) => game_callback (game));
	}

	private Game create_game (MediaSet? media_set, Uri uri, string mime_type) throws Error {
		var uid = new Uid (Fingerprint.get_uid (uri, FINGERPRINT_PREFIX));
		var title = new FilenameTitle (uri);
		var media = new GriloMedia (title, MIME_TYPE_TGDB);
		var cover = new CompositeCover ({
			new LocalCover (uri),
			new GriloCover (media, uid)});

		var game = new Game (uid, uri, title, platform);
		game.media_set = media_set;
		game.set_cover (cover);

		return game;
	}

	public void set_game_added_callback (GameCallback game_callback) {
		game_added_callback = game_callback;
	}
}
