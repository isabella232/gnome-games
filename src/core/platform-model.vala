// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PlatformModel : Object, ListModel {
	private GameModel game_model;
	private Sequence<Platform> sequence;
	private int n_platforms;
	private HashTable<Platform, uint> n_games;

	public PlatformModel (GameModel game_model) {
		this.game_model = game_model;
		sequence = new Sequence<Platform> ();
		n_platforms = 0;
		n_games = new HashTable<Platform, uint> (Platform.hash, Platform.equal);

		uint n = game_model.get_n_items ();
		for (uint i = 0; i < n; i++) {
			var game = game_model.get_item (i) as Game;
			var platform = game.platform;

			if (n_games[platform] == 0) {
				sequence.append (platform);
				n_platforms++;
			}

			n_games[platform] = n_games[platform] + 1;
		}

		sequence.sort (Platform.compare);

		items_changed (0, get_n_items (), 0);

		game_model.game_added.connect (game_added);
		game_model.game_removed.connect (game_removed);
	}

	public Object? get_item (uint position) {
		var iter = sequence.get_iter_at_pos ((int) position);

		return iter.get ();
	}

	public Type get_item_type () {
		return typeof (Platform);
	}

	public uint get_n_items () {
		return n_platforms;
	}

	private void game_added (Game game) {
		var platform = game.platform;

		if (n_games[platform] == 0) {
			var iter = sequence.insert_sorted (platform, Platform.compare);
			items_changed (iter.get_position (), 0, 1);
		}

		n_games[platform] = n_games[platform] + 1;
	}

	private void game_removed (Game game) {
		var platform = game.platform;

		n_games[platform] = n_games[platform] - 1;

		if (n_games[platform] == 0) {
			var iter = sequence.lookup (platform, Platform.compare);
			var pos = iter.get_position ();
			iter.remove ();
			items_changed (pos, 1, 0);
		}
	}
}
