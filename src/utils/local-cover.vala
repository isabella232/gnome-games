// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.LocalCover : Object, Cover {
	private Uri uri;
	private GLib.Icon? icon;

	public LocalCover (Uri uri) {
		this.uri = uri;
	}

	public async GLib.Icon? get_cover () {
		if (icon != null)
			return icon;

		try {
			var cover_path = yield get_cover_path ();
			if (cover_path != null)
				load_cover (cover_path);
		}
		catch (Error e) {
			warning (e.message);
		}

		return icon;
	}

	private async string? get_cover_path () throws Error {
		var cover_path = yield get_sibbling_cover_path ();
		if (cover_path == null)
			cover_path = yield get_directory_cover_path ();

		return cover_path;
	}

	private async string? get_sibbling_cover_path () throws Error {
		var file = uri.to_file ();
		var parent = file.get_parent ();
		if (parent == null)
			return null;

		var basename = file.get_basename ();
		var splitted_basename = basename.split (".");
		var prefix = splitted_basename.length == 1 ? basename : string.joinv (".", splitted_basename[0:splitted_basename.length - 1]);

		string cover_path = null;
		var directory = new Directory (parent);
		var attributes = string.join (",", FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_FAST_CONTENT_TYPE);
		yield directory.foreach_async (attributes, (sibbling) => {
			var sibbling_basename = sibbling.get_name ();
			if (sibbling_basename == basename)
				return false;

			if (!sibbling_basename.has_prefix (prefix))
				return false;

			var type = sibbling.get_attribute_string (FileAttribute.STANDARD_FAST_CONTENT_TYPE);
			if (!type.has_prefix ("image"))
				return false;

			var sibbling_file = parent.get_child (sibbling_basename);
			cover_path = sibbling_file.get_path ();

			return true;
		});

		return cover_path;
	}

	private async string? get_directory_cover_path () throws Error {
		var file = uri.to_file ();
		var parent = file.get_parent ();
		if (parent == null)
			return null;

		string cover_path = null;
		var directory = new Directory (parent);
		var attributes = string.join (",", FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_FAST_CONTENT_TYPE);
		yield directory.foreach_async (attributes, (sibbling) => {
			var sibbling_basename = sibbling.get_name ();
			if (!sibbling_basename.has_prefix ("cover.") &&
			    !sibbling_basename.has_prefix ("folder."))
				return false;

			var type = sibbling.get_attribute_string (FileAttribute.STANDARD_FAST_CONTENT_TYPE);
			if (!type.has_prefix ("image"))
				return false;

			var sibbling_file = parent.get_child (sibbling_basename);
			cover_path = sibbling_file.get_path ();

			return true;
		});

		return cover_path;
	}

	private void load_cover (string cover_path) {
		if (!FileUtils.test (cover_path, FileTest.EXISTS))
			return;

		var file = File.new_for_path (cover_path);
		icon = new FileIcon (file);
	}
}
