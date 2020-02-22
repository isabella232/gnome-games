// This file is part of GNOME Games. License: GPL-3.0+.

[DBus (name = "org.gnome.Shell.SearchProvider2")]
private class Games.SearchProvider : Object {
	private const string DB_QUERY_BASE = "SELECT games.uid, title FROM games WHERE %s;";
	private const string DB_QUERY_LIKE = "title LIKE ?";
	private const string DB_QUERY_AND = " AND ";

	private Application application;
	private HashTable<string, string> games;

	internal SearchProvider (Application app) {
		application = app;
	}

	private bool filter_by_game (string[] terms, string title) {
		if (terms.length == 0)
			return true;

		foreach (var term in terms)
			if (!(term.casefold () in title.casefold ()))
				return false;

		return true;
	}

	public async string[] get_initial_result_set (string[] terms) throws Error {
		application.hold ();

		var result = fetch_games (terms);

		application.release ();

		return result;
	}

	public async string[] get_subsearch_result_set (string[] previous_results, string[] terms) throws Error {
		application.hold ();

		string[] results = {};
		foreach (var uid in previous_results) {
			var game = games[uid];

			if (filter_by_game (terms, game))
				results += uid;
		}

		application.release ();

		return results;
	}

	private static int compare_cache_dirs (File file1, File file2) {
		var name1 = file1.get_basename ();
		var name2 = file2.get_basename ();

		int size1 = int.parse (name1);
		int size2 = int.parse (name2);

		if (size1 < size2)
			return -1;

		if (size1 > size2)
			return 1;

		return strcmp (name1, name2);
	}

	private async File? find_game_image (string uid, string subdir_name) throws Error {
		var cache_dir = Environment.get_user_cache_dir ();
		var path = @"$cache_dir/gnome-games/$subdir_name/";

		var subdir = File.new_for_path (path);

		var enumerator = yield subdir.enumerate_children_async ("standard::*",
		                                                        FileQueryInfoFlags.NONE);

		var list = new List<File> ();

		FileInfo info;
		while ((info = enumerator.next_file (null)) != null) {
			if (info.get_file_type () != FileType.DIRECTORY)
				continue;

			list.prepend (enumerator.get_child (info));
		}

		list.sort (compare_cache_dirs);

		foreach (var dir in list) {
			var child = dir.get_child (@"$uid.png");

			if (child.query_exists ())
				return child;
		}

		return null;
	}

	private async File? get_game_image (string uid) throws Error {
		var cover = yield find_game_image (uid, "covers");
		if (cover != null)
			return cover;

		return yield find_game_image (uid, "icons");
	}

	public async HashTable<string, Variant>[] get_result_metas (string[] results) throws Error {
		application.hold ();

		var result = new GenericArray<HashTable<string, Variant>> ();

		foreach (var uid in results) {
			var title = games[uid];
			var image = yield get_game_image (uid);

			GLib.Icon icon;
			if (image != null)
				icon = new FileIcon (image);
			else
				icon = new ThemedIcon ("%s-symbolic".printf (Config.APPLICATION_ID));

			var metadata = new HashTable<string, Variant> (str_hash, str_equal);

			metadata.insert ("id", uid);
			metadata.insert ("name", title);
			metadata.insert ("icon", icon.to_string ());

			result.add (metadata);
		}

		application.release ();

		return result.data;
	}

	public void activate_result (string uid, string[] terms, uint32 timestamp) throws Error {
		run_with_args ({ "--uid", uid });
	}

	public void launch_search (string[] terms, uint32 timestamp) throws Error {
		string[] args = {};

		foreach (var term in terms) {
			args += "--search";
			args += term;
		}

		run_with_args (args);
	}

	private void run_with_args (string[] run_args) {
		application.hold ();

		try {
			string[] args = { "gnome-games" };

			foreach (var arg in run_args)
				args += arg;

			Process.spawn_async (null, args, null, SpawnFlags.SEARCH_PATH, null, null);
		}
		catch (Error error) {
			critical ("Couldn't launch search: %s", error.message);
		}

		application.release ();
	}

	private string get_query_for_n_terms (int n) {
		string[] query_terms = {};

		for (int i = 0; i < n; i++)
			query_terms += DB_QUERY_LIKE;

		return DB_QUERY_BASE.printf (string.joinv (DB_QUERY_AND, query_terms));
	}

	private string[] fetch_games (string[] terms) {
		var data_dir = Environment.get_user_data_dir ();
		var path = @"$data_dir/gnome-games/database.sqlite3";

		Sqlite.Database db;
		var result = Sqlite.Database.open (path, out db);

		if (result != Sqlite.OK) {
			critical ("Couldn’t open the database for %s", path);
			return {};
		}

		var query = get_query_for_n_terms (terms.length);

		Sqlite.Statement statement;
		result = db.prepare_v2 (query, query.length, out statement);

		if (result != Sqlite.OK) {
			critical ("Preparation failed: %s", db.errmsg ());
			return {};
		}

		for (int i = 0; i < terms.length; i++) {
			result = statement.bind_text (i + 1, "%%%s%%".printf (terms[i]));

			if (result != Sqlite.OK) {
				critical ("Couldn't bind value: %s", db.errmsg ());
				return {};
			}
		}

		games = new HashTable<string, string> (str_hash, str_equal);
		var results = new GenericArray<string> ();

		while (statement.step () == Sqlite.ROW) {
			var uid = statement.column_text (0);
			var title = statement.column_text (1);

			games[uid] = title;
			results.add (uid);
		}

		results.sort_with_data ((a, b) => {
			return games[a].collate (games[b]);
		});

		return results.data;
	}
}

// This has to be a Gtk.Application and not GLib.Application because
// we sort games using string.collate() so the locale must be correct
public class Games.SearchProviderApplication : Gtk.Application {
	internal SearchProviderApplication () {
		Object (application_id: Config.APPLICATION_ID + ".SearchProvider",
		        flags: ApplicationFlags.IS_SERVICE,
		        inactivity_timeout: 10000);
	}

	protected override bool dbus_register (DBusConnection connection, string object_path) {
		try {
			var provider = new SearchProvider (this);
			connection.register_object (object_path, provider);
		}
		catch (IOError e) {
			warning ("Could not register search provider: %s", e.message);
			quit ();
		}

		return true;
	}
}

int main () {
	return new Games.SearchProviderApplication ().run ();
}
