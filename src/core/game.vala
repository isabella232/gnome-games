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
	public abstract Runner get_runner () throws Error;
}
