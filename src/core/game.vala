// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Game : Object {
	public abstract string name { get; }

	public abstract Uid get_uid ();
	public abstract Icon get_icon ();
	public abstract Cover get_cover ();
	public abstract ReleaseDate get_release_date ();
	public abstract Cooperative get_cooperative ();
	public abstract Genre get_genre ();
	public abstract Players get_players ();
	public abstract Developer get_developer ();
	public abstract Publisher get_publisher ();
	public abstract Runner get_runner () throws Error;

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
