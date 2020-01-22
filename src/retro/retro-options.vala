// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.RetroOptions : Object {
	public const string OPTIONS_GROUP = "Options";

	private KeyFile keyfile;

	public RetroOptions (string filename) throws Error {
		keyfile = new KeyFile ();
		keyfile.load_from_file (filename, KeyFileFlags.NONE);
	}

	public void apply (Retro.Core core) throws Error {
		var options_keys = keyfile.get_keys (OPTIONS_GROUP);

		foreach (var key in options_keys) {
			var val = keyfile.get_string (OPTIONS_GROUP, key);

			core.override_option_default (key, val);
		}
	}
}
