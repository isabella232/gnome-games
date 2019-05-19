// This file is part of GNOME Games. License: GPL-3.0+.

public errordomain Games.CompressionError {
	CLOSING_FAILED,
	COULDNT_ENUMERATE_CHILDREN,
	COULDNT_WRITE_HEADER,
	COULDNT_WRITE_FILE,
	INITIALIZATION_FAILED,
}

public errordomain Games.ExtractionError {
	CLEANUP_FAILED,
	COULDNT_READ_HEADER,
	DIDNT_REACH_EOF,
}

public class Games.FileOperations {
	public static void compress_dir (string name, File parent_dir, File export_data, string[]? exclude_files = null) throws CompressionError {
		var archive = new Archive.Write ();
		archive.add_filter_gzip ();
		archive.set_format_pax_restricted ();
		archive.open_filename (name);

		backup_data (parent_dir, export_data, archive, exclude_files);
		if (archive.close () != Archive.Result.OK) {
			var error_message = _("Error: %s (%d)").printf (archive.error_string (), archive.errno ());
			throw new CompressionError.CLOSING_FAILED (error_message);
		}
	}

	private static void backup_data (File parent, File dir, Archive.Write archive, string[] exclusions) throws CompressionError {
		var dtype = dir.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

		if (dtype == FileType.DIRECTORY) {
			try {
				var dir_children = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				FileInfo dir_info;
				while ((dir_info = dir_children.next_file ()) != null) {
					var file = dir.get_child (dir_info.get_name ());
					backup_data (parent, file, archive, exclusions);
				}
			}
			catch (Error e) {
				throw new CompressionError.COULDNT_ENUMERATE_CHILDREN (e.message);
			}
		}
		else {
			foreach (var filename in exclusions)
				if (dir.get_parse_name () == filename)
					return;
			compress_files (parent, dir, archive);
		}
	}

	private static void compress_files (File parent_working_dir, File export_dir, Archive.Write export_archive) throws CompressionError {
		FileInfo export_info;
		FileInputStream input_stream;
		DataInputStream data_input_stream;

		try {
			var attributes = ("%s,%s").printf (FileAttribute.STANDARD_SIZE ,FileAttribute.TIME_MODIFIED);
			export_info = export_dir.query_info (attributes, FileQueryInfoFlags.NONE);
			input_stream = export_dir.read ();
			data_input_stream = new DataInputStream (input_stream);
		}
		catch (Error e) {
			throw new CompressionError.INITIALIZATION_FAILED (e.message);
		}

		var entry = new Archive.Entry ();
		var timeval = export_info.get_modification_time ();
		entry.set_pathname (parent_working_dir.get_relative_path (export_dir));
		entry.set_size ((Archive.int64_t) export_info.get_size ());
		entry.set_mtime ((time_t) timeval.tv_sec, 0);
		entry.set_filetype ((Archive.FileType) Posix.S_IFREG);
		entry.set_perm (0644);
		if (export_archive.write_header (entry) != Archive.Result.OK) {
			var error_msg = _("Error writing “%s”: %s (%d)").printf (export_dir.get_path (), export_archive.error_string (), export_archive.errno ());
			throw new CompressionError.COULDNT_WRITE_HEADER (error_msg);
		}

		size_t bytes_read;
		uint8[] buffer = new uint8[64];
		try {
			while (data_input_stream.read_all (buffer, out bytes_read)) {
				if (bytes_read <= 0)
					break;

				export_archive.write_data (buffer);
			}
		}
		catch (Error e) {
			throw new CompressionError.COULDNT_WRITE_FILE (e.message);
		}
	}

	public static void delete_files (File file, string[] exclusions) throws Error {
		var dtype = file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);

		if (dtype == FileType.DIRECTORY) {
			var file_children = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file_info;
			while ((file_info = file_children.next_file ()) != null) {
				var child = file.get_child (file_info.get_name ());
				delete_files (child, exclusions);
			}
		}
		else {
			foreach (var filename in exclusions)
				if (file.get_parse_name () == filename)
					return;
			file.delete ();
		}
	}

	public static void extract_archive (string archive_path, string extract_dir, string[] exclude) throws ExtractionError {
		try {
			var file_dir = File.new_for_path (extract_dir);
			delete_files (file_dir, exclude);
		}
		catch (Error e) {
			throw new ExtractionError.CLEANUP_FAILED (e.message);
		}

		var restore_archive = new Archive.Read ();
		restore_archive.support_format_all ();
		restore_archive.support_filter_all ();

		var flags = Archive.ExtractFlags.TIME | Archive.ExtractFlags.PERM;

		var extractor_archive = new Archive.WriteDisk ();
		extractor_archive.set_options (flags);
		extractor_archive.set_standard_lookup ();

		restore_archive.open_filename (archive_path, /* block_size */ 10240);

		unowned Archive.Entry entry;
		Archive.Result last_result;
		while ((last_result = restore_archive.next_header (out entry)) == Archive.Result.OK) {
			var dir_pathname = ("%s/%s").printf (extract_dir, entry.pathname ());
			entry.set_pathname (dir_pathname);
			if (extractor_archive.write_header (entry) != Archive.Result.OK)
				throw new ExtractionError.COULDNT_READ_HEADER ("%s\n", extractor_archive.error_string ());

			uint8[] buffer = new uint8[64];
			size_t buffer_length;
			while (restore_archive.read_data_block (out buffer, out buffer_length) == Archive.Result.OK)
				if (extractor_archive.write_data_block (buffer, buffer_length) != Archive.Result.OK)
					break;
		}

		if (last_result != Archive.Result.EOF)
			throw new ExtractionError.DIDNT_REACH_EOF ("%s (%d)", restore_archive.error_string (), restore_archive.errno ());
	}
}
