// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericUriGameFactory : Object, UriGameFactory {
	private GameUriAdapter game_uri_adapter;
	private HashTable<Uri, Game> game_for_uri;
	private string[] mime_types;
	private string[] schemes;
	private unowned GameCallback game_added_callback;

	public GenericUriGameFactory (GameUriAdapter game_uri_adapter) {
		this.game_uri_adapter = game_uri_adapter;
		game_for_uri = new HashTable<Uri, Game> (Uri.hash, Uri.equal);
		mime_types = {};
		schemes = {};
	}

	public string[] get_mime_types () {
		return mime_types;
	}

	public void add_mime_type (string mime_type) {
		mime_types += mime_type;
	}

	public string[] get_schemes () {
		return schemes;
	}

	public void add_scheme (string scheme) {
		schemes += scheme;
	}

	public void add_uri (Uri uri) {
		if (game_for_uri.contains (uri))
			return;

		try {
			var game = game_uri_adapter.game_for_uri (uri);
			game_for_uri[uri] = game;

			if (game_added_callback != null)
				game_added_callback (game);
		}
		catch (Error e) {
			debug (e.message);
		}
	}

	public Game? query_game_for_uri (Uri uri) {
		if (game_for_uri.contains (uri))
			return game_for_uri[uri];

		return null;
	}

	public void foreach_game (GameCallback game_callback) {
		var games = game_for_uri.get_values ();
		foreach (var game in games)
			game_callback (game);
	}

	public void set_game_added_callback (GameCallback game_callback) {
		game_added_callback = game_callback;
	}
}
