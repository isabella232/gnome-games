// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DesktopTrackerAppInfo : Object {
	private const string TRACKER_KEY_PREFIX_NFO = "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#";
	private const string TRACKER_KEY_PREFIX_NIE = "http://www.semanticdesktop.org/ontologies/2007/01/19/nie#";
	private const string TRACKER_KEY_CMDLINE = TRACKER_KEY_PREFIX_NFO + "softwareCmdLine";
	private const string TRACKER_KEY_ICON = TRACKER_KEY_PREFIX_NFO + "softwareIcon";
	private const string TRACKER_KEY_TITLE = TRACKER_KEY_PREFIX_NIE + "title";
	private const string TRACKER_KEY_FILE_NAME = TRACKER_KEY_PREFIX_NFO + "fileName";
	private const string TRACKER_KEY_CATEGORY = TRACKER_KEY_PREFIX_NIE + "isLogicalPartOf";

	private TrackerMetadata metadata;

	public DesktopTrackerAppInfo (Uri uri) throws Error {
		var connection = Tracker.Sparql.Connection.@get ();
		metadata = new TrackerMetadata (connection, uri);
	}

	public GLib.Icon? get_icon () {
		var val = metadata.get_object (TRACKER_KEY_ICON);
		var icon = val.replace ("urn:theme-icon:", "");

		try {
			return GLib.Icon.new_for_string (icon);
		} catch (Error e) {
			debug (e.message);
			return null;
		}
	}

	public string get_title () {
		return metadata.get_object (TRACKER_KEY_TITLE);
	}

	public string get_filename () {
		return metadata.get_object (TRACKER_KEY_FILE_NAME);
	}

	public string get_command () {
		return metadata.get_object (TRACKER_KEY_CMDLINE);
	}

	public string[] get_categories () {
		var categories = metadata.get_all_objects (TRACKER_KEY_CATEGORY);
		string[] result = {};
		foreach (var category in categories)
			result += category.replace ("urn:software-category:", "");

		return result;
	}

	public string get_executable () {
		var cmdline = get_command ();
		var args = cmdline.split(" ");

		// FIXME
		if (args[0].has_suffix ("flatpak")) {
			var index = 1;
			while (args[index].has_prefix ("-"))
				index++;

			return args[index];
		}

		return args[0];
	}
}
