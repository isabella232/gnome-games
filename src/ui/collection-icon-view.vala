// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-icon-view.ui")]
private class Games.CollectionIconView : Gtk.FlowBoxChild {
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private CollectionThumbnail thumbnail;

	public bool checked { get; set; }
	public bool is_selection_mode { get; set; }

	private Collection _collection;
	public Collection collection {
		get { return _collection; }
		construct set {
			_collection = value;

			title.label = collection.title;
			thumbnail.collection = collection;
		}
	}

	construct {
		get_style_context ().add_class ("collection-icon-view");
	}

	public CollectionIconView (Collection collection) {
		Object (collection: collection);
	}

	public static uint hash (CollectionIconView key) {
		return Collection.hash (key.collection);
	}

	public static bool equal (CollectionIconView a, CollectionIconView b) {
		return Collection.equal (a.collection, b.collection);
	}
}
