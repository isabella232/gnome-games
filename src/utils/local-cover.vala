// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.LocalCover : Object, Cover {
	private Uri uri;
	private GLib.Icon? icon;
	private GenericSet<string> extensions;

	construct {
		extensions = new GenericSet<string> (str_hash, str_equal);

		extensions.add ("cover");
		foreach (var format in Gdk.Pixbuf.get_formats ())
			foreach (var extension in format.get_extensions ())
				extensions.add (extension);
	}

	public LocalCover (Uri uri) {
		this.uri = uri;
	}

	public async GLib.Icon? get_cover () {
		if (icon != null)
			return icon;

		load_cover ();

		return icon;
	}

	private string get_cover_path () {
		var basename = uri.to_file ().get_basename ();
		var prefix = basename.substring (0, basename.last_index_of ("."));

		var cover_path = get_cover_path_for (prefix);
		if (cover_path == null)
			cover_path = get_cover_path_for ("folder");
		if (cover_path == null)
			cover_path = get_cover_path_for ("cover");

		return cover_path;
	}

	private string? get_cover_path_for (string prefix) {
		var parent = uri.to_file ().get_parent ();
		if (parent == null)
			return null;

		foreach (var extension in extensions.get_values ()) {
			var cover_basename = @"$prefix.$extension";
			var cover_path = Path.build_filename (parent.get_path (), cover_basename);

			if (FileUtils.test (cover_path, FileTest.EXISTS))
				return cover_path;
		}

		return null;
	}

	private void load_cover () {
		var cover_path = get_cover_path ();

		if (cover_path == null)
			return;

		var file = File.new_for_path (cover_path);
		icon = new FileIcon (file);
	}
}
