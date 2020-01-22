public class Games.Savestate : Object {
	public string path { get; construct; }
	public Platform platform { get; construct; }
	public string core { get; construct; }

	// Automatic means whether the savestate was created automatically when
	// quitting/loading the game or manually by the user using the Save button
	public bool is_automatic { get; set; }
	public string name { get; set; }
	public DateTime? creation_date { get; set; }
	public double screenshot_aspect_ratio { get; set; }

	private static Savestate load (Platform platform, string core_id, string path) {
		var type = platform.get_savestate_type ();

		var savestate = Object.new (type,
		                            "path", path,
		                            "platform", platform,
		                            "core", core_id,
		                            null) as Savestate;

		savestate.load_keyfile ();

		return savestate;
	}

	private void load_keyfile () {
		var metadata_file_path = Path.build_filename (path, "metadata");
		var metadata_file = File.new_for_path (metadata_file_path);

		if (!metadata_file.query_exists ())
			return;

		var keyfile = new KeyFile ();

		try {
			keyfile.load_from_file (metadata_file_path, KeyFileFlags.NONE);

			load_metadata (keyfile);
		}
		catch (Error e) {
			critical ("Failed to load metadata for snapshot at %s: %s", path, e.message);
		}
	}

	public string get_snapshot_path () {
		return Path.build_filename (path, "snapshot");
	}

	public string get_save_ram_path () {
		return Path.build_filename (path, "save");
	}

	public string get_screenshot_path () {
		return Path.build_filename (path, "screenshot");
	}

	public string get_save_directory_path () {
		return Path.build_filename (path, "save-dir");
	}

	public bool has_media_data () {
		var media_path = Path.build_filename (path, "media");

		return FileUtils.test (media_path, FileTest.EXISTS);
	}

	// Currently all games only have a number as media_data, so this method
	// returns an int, but in the future it might return an abstract MediaData
	public int get_media_data () throws Error {
		var media_path = Path.build_filename (path, "media");

		if (!FileUtils.test (media_path, FileTest.EXISTS))
			throw new FileError.ACCES ("Snapshot at %s does not contain media file", path);

		string contents;
		FileUtils.get_contents (media_path, out contents);

		int media_number = int.parse (contents);

		return media_number;
	}

	public void set_media_data (MediaSet media_set) throws Error {
		var media_path = Path.build_filename (path, "media");
		var contents = media_set.selected_media_number.to_string ();

		FileUtils.set_contents (media_path, contents, contents.length);
	}

	public Savestate clone_in_tmp () throws Error {
		var tmp_savestate_path = prepare_empty_savestate_in_tmp ();
		var tmp_savestate_dir = File.new_for_path (tmp_savestate_path);
		var cloned_savestate_dir = File.new_for_path (path);

		FileOperations.copy_contents (cloned_savestate_dir, tmp_savestate_dir);

		return Savestate.load (platform, core, tmp_savestate_path);
	}

	// This method is used to save the savestate in /tmp as a regular savestate
	// inside the savestates directory of a game
	// It names the newly created savestate using the creation date in the
	// metadata file
	public Savestate save_in (string game_savestates_dir_path) throws Error {
		var copied_dir = File.new_for_path (path);
		var new_savestate_dir_path = Path.build_filename (game_savestates_dir_path, creation_date.to_string ());
		var new_savestate_dir = File.new_for_path (new_savestate_dir_path);

		while (new_savestate_dir.query_exists ()) {
			new_savestate_dir_path += "_";
			new_savestate_dir = File.new_for_path (new_savestate_dir_path);
		}

		FileOperations.copy_dir (copied_dir, new_savestate_dir);

		return Savestate.load (platform, core, new_savestate_dir_path);
	}

	protected virtual void load_metadata (KeyFile keyfile) throws KeyFileError {
		is_automatic = keyfile.get_boolean ("Metadata", "Automatic");

		if (is_automatic)
			name = null;
		else
			name = keyfile.get_string ("Metadata", "Name");

		var creation_date_str = keyfile.get_string ("Metadata", "Creation Date");
		creation_date = new DateTime.from_iso8601 (creation_date_str, new TimeZone.local ());

		// Migrated savestates aren't going to have this
		if (keyfile.has_group ("Screenshot"))
			screenshot_aspect_ratio = keyfile.get_double ("Screenshot", "Aspect Ratio");
		else
			screenshot_aspect_ratio = 0;
	}

	protected virtual void save_metadata (KeyFile keyfile) {
		keyfile.set_boolean ("Metadata", "Automatic", is_automatic);
		if (name != null)
			keyfile.set_string ("Metadata", "Name", name);
		keyfile.set_string ("Metadata", "Creation Date", creation_date.to_string ());

		// FIXME: This is unused
		keyfile.set_string ("Metadata", "Platform", platform.get_uid_prefix ());
		keyfile.set_string ("Metadata", "Core", core);

		keyfile.set_double ("Screenshot", "Aspect Ratio", screenshot_aspect_ratio);
	}

	public void write_metadata () throws Error {
		var metadata_file_path = Path.build_filename (path, "metadata");
		var metadata_file = File.new_for_path (metadata_file_path);
		var metadata = new KeyFile ();

		if (metadata_file.query_exists ())
			metadata_file.@delete ();

		save_metadata (metadata);

		metadata.save_to_file (metadata_file_path);
	}

	public void delete_from_disk () {
		var savestate_dir = File.new_for_path (path);

		// Treat errors locally in this method because there isn't much that
		// can go wrong with deleting files
		try {
			FileOperations.delete_files (savestate_dir, {});
		}
		catch (Error e) {
			warning ("Failed to delete snapshot at %s: %s", path, e.message);
		}
	}

	public static Savestate[] get_game_savestates (Uid game_uid, Platform platform, string core_id) throws Error {
		var data_dir_path = Application.get_data_dir ();
		var savestates_dir_path = Path.build_filename (data_dir_path, "savestates");
		var uid_str = game_uid.get_uid ();
		var core_id_prefix = core_id.replace (".libretro", "");
		var game_savestates_dir_path = Path.build_filename (savestates_dir_path, uid_str + "-" + core_id_prefix);
		var game_savestates_dir_file = File.new_for_path (game_savestates_dir_path);

		if (!game_savestates_dir_file.query_exists ()) {
			// The game has no savestates directory so we create one
			game_savestates_dir_file.make_directory_with_parents ();
			return {}; // Obviously no savestates available either
		}

		var game_savestates_dir = Dir.open (game_savestates_dir_path);

		Savestate[] game_savestates = {};
		string savestate_name = null;

		while ((savestate_name = game_savestates_dir.read_name ()) != null) {
			var savestate_path = Path.build_filename (game_savestates_dir_path, savestate_name);
			game_savestates += Savestate.load (platform, core_id, savestate_path);
		}

		// Sort the savestates array by creation dates
		qsort_with_data (game_savestates, sizeof (Savestate), compare_savestates_path);

		return game_savestates;
	}

	private static int compare_savestates_path (Savestate s1, Savestate s2) {
		if (s1.path < s2.path)
			return 1;

		if (s1.path == s2.path)
			return 0;

		// s1.path > s2.path
		return -1;
	}

	public static Savestate create_empty_in_tmp (Platform platform, string core_id) throws Error {
		return Savestate.load (platform, core_id, prepare_empty_savestate_in_tmp ());
	}

	// Returns the path of the newly created dir in tmp
	public static string prepare_empty_savestate_in_tmp () throws Error {
		var tmp_savestate_path = DirUtils.make_tmp ("games_savestate_XXXXXX");
		var save_dir_path = Path.build_filename (tmp_savestate_path, "save-dir");
		var save_dir = File.new_for_path (save_dir_path);

		save_dir.make_directory ();

		return tmp_savestate_path;
	}
}
