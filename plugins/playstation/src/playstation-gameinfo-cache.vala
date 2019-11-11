// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.PlaystationGameinfoCache : Object {
	private struct InfoCache {
		MediaSet media_set;
		InputCapabilities input_capabilities;
	}

	private HashTable<Uri, InfoCache?> info_for_uri;

	construct {
		info_for_uri = new HashTable<Uri, InfoCache?> (Uri.hash, Uri.equal);
	}

	public void store_info (Uri uri, MediaSet media_set, InputCapabilities input_capabilities) {
		info_for_uri[uri] = { media_set, input_capabilities };
	}

	public MediaSet get_media_set (Uri uri) {
		return info_for_uri[uri].media_set;
	}

	public InputCapabilities get_input_capabilities (Uri uri) {
		return info_for_uri[uri].input_capabilities;
	}
}
