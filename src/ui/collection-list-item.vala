// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-list-item.ui")]
private class Games.CollectionListItem : Hdy.ActionRow {
	public Collection collection { get; construct; }

	construct {
		title = collection.get_title ();
	}

	public CollectionListItem (Collection collection) {
		Object (collection: collection);
	}
}
