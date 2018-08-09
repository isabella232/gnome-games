// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.TrackerUriSource : Object, UriSource {
	private Tracker.Sparql.Connection connection { get; private set; }
	private TrackerUriQuery[] queries;
	private string prefix;

	public TrackerUriSource (Tracker.Sparql.Connection connection) {
		this.connection = connection;
	}

	public void set_prefix (string prefix) {
		this.prefix = prefix;
	}

	construct {
		queries = {};
		prefix = "";
	}

	public void add_query (TrackerUriQuery query) {
		queries += query;
	}

	public UriIterator iterator () {
		return new TrackerUriIterator (connection, queries, prefix);
	}
}
