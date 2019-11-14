// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.GameUriAdapter : Object {
	public abstract Game game_for_uri (Uri uri) throws Error;
}
