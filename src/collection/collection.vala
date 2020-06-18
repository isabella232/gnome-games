// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.Collection : Object {
	public signal void games_changed ();

	public abstract void load ();

	public abstract string get_id ();

	public abstract string get_title ();

	public abstract bool get_hide_stars ();

	public abstract GameModel get_game_model ();

	public abstract void add_games (Game[] games);

	public abstract void remove_games (Game[] games);

	public abstract void on_game_added (Game game);

	public abstract void on_game_removed (Game game);

	public abstract void on_game_replaced (Game game, Game prev_game);
}
