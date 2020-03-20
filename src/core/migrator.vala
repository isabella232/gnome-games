// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Migrator : Object {
	// Returns true if the migration wasn't necessary or
	// if it was performed succesfully
	public static bool apply_migration_if_necessary () {
		var data_dir_path = Application.get_data_dir ();
		var data_dir = File.new_for_path (data_dir_path);

		var backup_archive_path = Path.build_filename (data_dir_path, "exported_data.zip");
		var backup_archive = File.new_for_path (backup_archive_path);
		var database_path = Application.get_database_path ();
		string[] backup_excluded_files = { database_path, backup_archive_path };

		var version_file = data_dir.get_child (".version");

		// If the version file exists, there's no need
		// to apply the migration
		if (version_file.query_exists ())
			return true;

		info ("[Migrator]: Migration is necessary");

		// Attempt to create a backup of the previous data
		try {
			backup_archive.create (FileCreateFlags.NONE);
			FileOperations.compress_dir (backup_archive_path, data_dir, backup_excluded_files);
		}
		catch (Error e) {
			critical ("Unable to backup data, aborting migration: %s", e.message);
			return false;
		}

		try {
			// The migration executes file I/O which may result in errors being
			// thrown
			apply_migration (version_file);
		}
		catch (Error e) {
			critical ("Migration failed: %s", e.message);

			// Delete all directories from the data dir
			var savestates_dir_path = Path.build_filename (data_dir_path, "/savestates");
			var savestates_dir = File.new_for_path (savestates_dir_path);

			delete_files_no_errors (savestates_dir);
			delete_old_directories ();

			// Attempt to restore data from backup
			if (try_restore_data (backup_archive_path, data_dir_path, backup_excluded_files)) {
				// Successfully restored data from backup, deleting backup
				delete_files_no_errors (backup_archive);
			}
			else {
				// Something went seriously wrong here
				// Migration failed and restoring backup data also failed
				assert_not_reached ();
			}

			return false;
		}

		// Migration applied succesfully, deleting backup
		delete_files_no_errors (backup_archive);

		return true;
	}

	private static void apply_migration (File version_file) throws Error {
		// Create the version file
		version_file.create (FileCreateFlags.NONE);

		// Create the savestates dir
		var savestates_dir = File.new_for_path (get_savestates_dir_path ());

		// If the dir exists, we failed and there's already new data. Just bail
		if (savestates_dir.query_exists ())
			return;

		savestates_dir.make_directory ();

		// Currently any game has only one snapshot file
		// So for every snapshot file create a savestate
		var snapshots_dir_path = get_old_snapshots_dir_path ();
		var snapshots_dir = Dir.open (snapshots_dir_path, 0);
		var file_name = "";
		while ((file_name = snapshots_dir.read_name ()) != null) {
			if (!file_name.has_suffix (".snapshot"))
				continue; // Not a snapshot file

			// The snapshot files are curently named "[game_uid].snapshot"
			var file_name_tokens = file_name.split (".snapshot");
			var game_uid = file_name_tokens[0];
			create_first_game_savestate (game_uid);
		}

		delete_old_directories ();
	}

	private static void create_first_game_savestate (string game_uid) throws Error {
		// Inside the savestates dir there will be a sub-dir for each game
		// which will contain all of the savestates for that game
		// These sub-dirs will be named "[game_uid]-[core]"

		// Getting the core_id
		var platform = platform_from_game_uid (game_uid);
		var core_manager = RetroCoreManager.get_instance ();
		var preferred_core = core_manager.get_preferred_core (platform);
		var core_id = preferred_core.get_id ();

		// Create the directory for the game's savestates
		var core_id_prefix = core_id.replace (".libretro", ""); // Remove the ".libretro" from the core_id
		var game_savestates_dir_name = game_uid + "-" + core_id_prefix;
		var game_savestates_dir_path = Path.build_filename (get_savestates_dir_path (), game_savestates_dir_name);
		var game_savestates_dir = File.new_for_path (game_savestates_dir_path);

		game_savestates_dir.make_directory ();

		// Create the directory for the first savestate
		var now_time = new DateTime.now ();
		var now_time_str = now_time.to_string ();
		var savestate_dir_path = Path.build_filename (game_savestates_dir_path, now_time_str);
		var savestate_dir = File.new_for_path (savestate_dir_path);

		savestate_dir.make_directory ();

		// Use the currently existing game data (snapshot, screenshot,
		// save file, save dir) to populate the savestate
		var snapshots_dir_path = get_old_snapshots_dir_path ();
		var snapshot_path = Path.build_filename (snapshots_dir_path, game_uid + ".snapshot");
		var screenshot_path = Path.build_filename (snapshots_dir_path, game_uid + ".png");
		var saves_dir = get_old_saves_dir_path ();
		var save_dir_path = Path.build_filename (saves_dir, game_uid);
		var save_file_path = save_dir_path + ".save";
		var medias_dir = get_old_medias_dir_path ();
		var media_file_path = Path.build_filename (medias_dir, game_uid + ".media");

		var snapshot_file = File.new_for_path (snapshot_path);
		var screenshot_file = File.new_for_path (screenshot_path);
		var save_dir = File.new_for_path (save_dir_path);
		var save_file = File.new_for_path (save_file_path);
		var media_file = File.new_for_path (media_file_path);

		var savestate_snapshot_file_path = Path.build_filename (savestate_dir_path, "snapshot");
		var savestate_snapshot_file = File.new_for_path (savestate_snapshot_file_path);
		FileOperations.copy_contents (snapshot_file, savestate_snapshot_file);

		var savestate_screenshot_file_path = Path.build_filename (savestate_dir_path, "screenshot");
		var savestate_screenshot_file = File.new_for_path (savestate_screenshot_file_path);
		FileOperations.copy_contents (screenshot_file, savestate_screenshot_file);

		if (!save_dir.query_exists ())
			save_dir.make_directory ();

		var savestate_save_dir_path = Path.build_filename (savestate_dir_path, "save-dir");
		var savestate_save_dir = File.new_for_path (savestate_save_dir_path);
		FileOperations.copy_dir (save_dir, savestate_save_dir);

		if (save_file.query_exists ()) {
			var savestate_save_file_path = Path.build_filename (savestate_dir_path, "save");
			var savestate_save_file = File.new_for_path (savestate_save_file_path);
			FileOperations.copy_contents (save_file, savestate_save_file);
		}

		if (media_file.query_exists ()) {
			var savestate_media_file_path = Path.build_filename (savestate_dir_path, "media");
			var savestate_media_file = File.new_for_path (savestate_media_file_path);
			FileOperations.copy_contents (media_file, savestate_media_file);
		}

		// Create a KeyFile with additional data
		var metadata = new KeyFile ();
		var metadata_file_path = Path.build_filename (savestate_dir_path, "metadata");

		// Automatic means whether the savestate was created automatically when
		// quitting/loading the game or manually by the user using the Save button
		metadata.set_boolean ("Metadata", "Automatic", true);
		metadata.set_string ("Metadata", "Creation Date", now_time_str);
		metadata.set_string ("Metadata", "Platform", platform.get_uid_prefix ());
		metadata.set_string ("Metadata", "Core", core_id);
		metadata.save_to_file (metadata_file_path);
	}


	private static RetroPlatform platform_from_game_uid (string game_uid) {
		// [game_uid] is currently formed as "[platform]-[hash]"
		// So we can use the game_uid to get the platform
		var platforms_register = PlatformRegister.get_register ();
		var platforms = platforms_register.get_all_platforms ();

		string best_match = null;
		RetroPlatform result_platform = null;

		foreach (var platform in platforms) {
			var retro_platform = platform as RetroPlatform;

			if (retro_platform == null)
				continue; // not a RetroPlatform

			var platform_uid_prefix = platform.get_uid_prefix ();

			if (game_uid.contains (platform_uid_prefix)) {
				if (best_match == null || platform_uid_prefix.length > best_match.length) {
					best_match = platform_uid_prefix;
					result_platform = retro_platform;
				}
			}
		}

		return result_platform;
	}

	// Delete the old snapshots, saves and medias directories
	private static void delete_old_directories () {
		var snapshots_dir_path = get_old_snapshots_dir_path ();
		var saves_dir_path = get_old_saves_dir_path ();
		var medias_dir_path = get_old_medias_dir_path ();

		var snapshots_dir = File.new_for_path (snapshots_dir_path);
		var saves_dir = File.new_for_path (saves_dir_path);
		var medias_dir = File.new_for_path (medias_dir_path);

		delete_files_no_errors (snapshots_dir);
		delete_files_no_errors (saves_dir);
		delete_files_no_errors (medias_dir);
	}

	private static string get_old_snapshots_dir_path () {
		var data_dir = Application.get_data_dir ();

		return @"$data_dir/snapshots";
	}

	private static string get_old_saves_dir_path () {
		var data_dir = Application.get_data_dir ();

		return @"$data_dir/saves";
	}

	private static string get_old_medias_dir_path () {
		var data_dir = Application.get_data_dir ();

		return @"$data_dir/medias";
	}

	private static string get_savestates_dir_path () {
		var data_dir = Application.get_data_dir ();

		return @"$data_dir/savestates";
	}

	// Method for deleting files that treats errors locally because there isn't
	// much that can go wrong with deleting files
	private static void delete_files_no_errors (File file) {
		try {
			FileOperations.delete_files (file, {});
		}
		catch (Error e) {
			warning ("Cannot delete file %s: %s", file.get_path (), e.message);
		}
	}

	private static bool try_restore_data (string backup_archive_path, string data_dir_path, string[] backup_excluded_files) {
		try {
			FileOperations.extract_archive (backup_archive_path, data_dir_path, backup_excluded_files);
		}
		catch (Error e) {
			critical ("Failed to restore data from backup archive %s: %s", backup_archive_path, e.message);
			return false;
		}

		return true; // Succesfully restored data from backup
	}
}
