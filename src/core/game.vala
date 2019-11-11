// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Game : Object {
	public abstract string name { get; }

	public abstract Uid get_uid ();
	public abstract Uri get_uri ();
	public abstract Icon get_icon ();
	public abstract Cover get_cover ();
	public abstract Platform get_platform ();

	public bool matches_search_terms (string[] search_terms) {
		if (search_terms.length != 0)
			foreach (var term in search_terms)
				if (!(term.casefold () in name.casefold ()))
					return false;

		return true;
	}

	public static uint hash (Game key) {
		var uid = "";
		try {
			uid = key.get_uid ().get_uid ();
		}
		catch (Error e) {
			critical (e.message);
		}

		return str_hash (uid);
	}

	public static bool equal (Game a, Game b) {
		if (direct_equal (a, b))
			return true;

		var a_uid = "";
		try {
			a_uid = a.get_uid ().get_uid ();
		}
		catch (Error e) {
			critical (e.message);
		}

		var b_uid = "";
		try {
			b_uid = b.get_uid ().get_uid ();
		}
		catch (Error e) {
			critical (e.message);
		}

		return str_equal (a_uid, b_uid);
	}
}
