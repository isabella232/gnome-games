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

		game_model.game_added.connect (game_added);
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
		var platform = game.get_platform ();

		if (n_games[platform] == 0) {
			var iter = sequence.insert_sorted (platform, compare_func);
			items_changed (iter.get_position (), 0, 1);
		}

		n_games[platform] = n_games[platform] + 1;
	}

	private int compare_func (Platform a, Platform b) {
		return a.get_name ().collate (b.get_name ());
	}
}
