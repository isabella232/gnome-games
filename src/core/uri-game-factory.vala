// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.UriGameFactory : Object {
	public virtual string[] get_mime_types () {
		return {};
	}

	public virtual string[] get_schemes () {
		return {};
	}

	public abstract void add_uri (Uri uri);
	public abstract Game? query_game_for_uri (Uri uri);
	public abstract void foreach_game (GameCallback game_callback);
	public abstract void set_game_added_callback (GameCallback game_callback);
}
