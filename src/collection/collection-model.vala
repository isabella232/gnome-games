// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.CollectionModel : Object, ListModel {
	public signal void collection_added (Collection collection);

	private Sequence<Collection> sequence;
	private int n_collections;

	construct {
		sequence = new Sequence<Collection> ();
		n_collections = 0;
	}

	public Object? get_item (uint position) {
		var iter = sequence.get_iter_at_pos ((int) position);

		return iter.get ();
	}

	public Type get_item_type () {
		return typeof (Collection);
	}

	public uint get_n_items () {
		return n_collections;
	}

	public void add_collection (Collection collection) {
		var iter = sequence.insert_sorted (collection, Collection.compare);
		n_collections++;

		items_changed (iter.get_position (), 0, 1);
		collection_added (collection);
	}
}
