// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-icon-view.ui")]
private class Games.CollectionIconView : Gtk.FlowBoxChild {
	[GtkChild]
	private Gtk.Label title;

	private Collection _collection;
	public Collection collection {
		get { return _collection; }
		construct set {
			_collection = value;

			title.label = collection.get_title ();
			thumbnail.collection = collection;
		}
	}

	public CollectionIconView (Collection collection) {
		Object (collection: collection);
	}
}
