// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.CollectionManager : Object {
	public signal void collection_added (Collection collection);
	public signal void collection_removed (Collection collection);
	public signal void collection_empty_changed (Collection collection);

	private HashTable<string, Collection> collections;
	private Database database;

	private FavoritesCollection favorites_collection;
	private RecentlyPlayedCollection recently_played_collection;

	public uint n_user_collections { get; private set; }

	public CollectionManager (Database database) {
		this.database = database;
		collections = new HashTable<string, Collection> (str_hash, str_equal);

		add_favorites_collection ();
		add_recently_played_collection ();
		add_user_collections ();
		add_new_collection_placeholder ();

		collections.foreach ((key, val) => {
			val.load ();
		});
	}

	public void toggle_favorite (Game[] games) {
		var is_all_favorite = true;
		foreach (var game in games) {
			if (!game.is_favorite) {
				is_all_favorite = false;
				break;
			}
		}

		if (is_all_favorite)
			favorites_collection.remove_games (games);
		else
			favorites_collection.add_games (games);
	}

	public UserCollection? create_user_collection (string title) {
		var uuid = Uuid.string_random ();
		var user_collection = new UserCollection (uuid, title, database);

		try {
			if (!database.add_user_collection (user_collection))
				return null;

			collections[uuid] = user_collection;
			n_user_collections++;
			Idle.add (() => {
				collection_added (user_collection);
				return Source.REMOVE;
			});

			return user_collection;
		}
		catch (Error e) {
			critical ("%s", e.message);

			return null;
		}
	}

	public bool remove_user_collection (UserCollection collection) {
		try {
			if (!database.remove_user_collection (collection))
				return false;

			collections.remove (collection.get_id ());
			n_user_collections--;
			collection_removed (collection);
			return true;
		}
		catch (Error e) {
			critical ("%s", e.message);

			return false;
		}
	}

	public bool does_collection_title_exist (string title) {
		foreach (var collection in collections.get_values ())
			if (collection.get_title () == title)
				return true;

		return false;
	}

	private void add_user_collections () {
		try {
			var user_collections = database.get_user_collections ();
			user_collections.foreach ((collection) => {
				collections[collection.get_id ()] = collection;
				n_user_collections++;
				Idle.add (() => {
					collection_added (collection);
					return Source.REMOVE;
				});
			});
		}
		catch (Error e) {
			critical ("Failed to load user collections: %s", e.message);
		}
	}

	private void add_favorites_collection () {
		favorites_collection = new FavoritesCollection (database);
		favorites_collection.notify["is-empty"].connect (() => {
			Idle.add (() => {
				collection_empty_changed (favorites_collection);
				return Source.REMOVE;
			});
		});
		collections[favorites_collection.get_id ()] = favorites_collection;
		Idle.add (() => {
			collection_added (favorites_collection);
			return Source.REMOVE;
		});
	}

	private void add_recently_played_collection () {
		recently_played_collection = new RecentlyPlayedCollection (database);
		recently_played_collection.notify["is-empty"].connect (() => {
			Idle.add (() => {
				collection_empty_changed (recently_played_collection);
				return Source.REMOVE;
			});
		});
		collections[recently_played_collection.get_id ()] = recently_played_collection;
		Idle.add (() => {
			collection_added (recently_played_collection);
			return Source.REMOVE;
		});
	}

	private void add_new_collection_placeholder () {
		var placeholder = new DummyAddCollection ();
		collections[placeholder.get_id ()] = placeholder;
		Idle.add (() => {
			collection_added (placeholder);
			return Source.REMOVE;
		});
	}
}
