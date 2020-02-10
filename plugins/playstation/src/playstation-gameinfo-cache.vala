// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.PlaystationGameinfoCache : Object {
	private HashTable<Uri, MediaSet> info_for_uri;

	construct {
		info_for_uri = new HashTable<Uri, MediaSet> (Uri.hash, Uri.equal);
	}

	public void store_info (Uri uri, MediaSet media_set) {
		info_for_uri[uri] = media_set;
	}

	public MediaSet get_media_set (Uri uri) {
		return info_for_uri[uri];
	}
}
