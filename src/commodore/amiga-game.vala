// This file is part of GNOME Games. License: GPLv3

private class Games.AmigaGame : Object, Game {
	private const string FINGERPRINT_PREFIX = "amiga-";
	private const string MODULE_BASENAME = "libretro-amiga.so";

	private string _uid;
	public string uid {
		get {
			if (_uid != null)
				return _uid;

			var fingerprint = Fingerprint.get_for_file_uri (uri);
			_uid = FINGERPRINT_PREFIX + fingerprint;

			return _uid;
		}
	}

	private string _name;
	public string name {
		get { return _name; }
	}

	public Icon? icon {
		get { return null; }
	}

	private string uri;
	private string path;

	public AmigaGame (string uri) throws Error {
		this.uri = uri;

		var file = File.new_for_uri (uri);
		path = file.get_path ();

		var name = file.get_basename ();
		name = /\.adf$/.replace (name, name.length, 0, "");
		name = name.split ("(")[0];
		_name = name.strip ();
	}

	public Runner get_runner () throws RunError {
		return new RetroRunner (MODULE_BASENAME, path, uid);
	}
}
