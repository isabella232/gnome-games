// This file is part of GNOME Games. License: GPL-3.0+.

private struct Games.TrackerMetadataPair {
	public string predicate;
	public string object;
}

public class Games.TrackerMetadata : Object {
	private Tracker.Sparql.Connection connection;
	private Uri uri;
	private Tracker.Sparql.Cursor cursor;
	private TrackerMetadataPair[] pairs;

	public TrackerMetadata (Tracker.Sparql.Connection connection, Uri uri) {
		this.connection = connection;
		this.uri = uri;
		cursor = null;
	}

	private void perform_query () throws Error {
		var uri_string = uri.to_string ();
		var query = @"SELECT ?predicate ?object WHERE { <$uri_string> ?predicate ?object }";

		cursor = connection.query (query);

		pairs = {};
		while (cursor.next ()) {
			var predicate = cursor.get_string (0);
			var object = cursor.get_string (1);

			var pair = TrackerMetadataPair ();
			pair.predicate = predicate;
			pair.object = object;
			pairs += pair;
		}
	}

	private void ensure_is_loaded () {
		if (pairs == null) {
			try {
				perform_query ();
			}
			catch (Error e) {
				critical (e.message);
			}
		}
	}

	public string get_object (string predicate) {
		ensure_is_loaded ();

		foreach (var pair in pairs)
			if (pair.predicate == predicate)
				return pair.object;

		return "";
	}

	public string[] get_all_objects (string predicate) {
		ensure_is_loaded ();

		string[] result = {};
		foreach (var pair in pairs)
			if (pair.predicate == predicate)
				result += pair.object;

		return result;
	}
}
