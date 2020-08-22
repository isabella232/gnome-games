// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/empty-search.ui")]
private class Games.EmptySearch : Gtk.Box {
	public enum SearchItem {
		GAME,
		COLLECTION;

		public string get_title () {
			switch (this) {
			case GAME:
				return _("No games found");

			case COLLECTION:
				return _("No collections found");

			default:
				assert_not_reached ();
			}
		}
	}

	[GtkChild]
	private Gtk.Label title;

	private SearchItem _search_item;
	public SearchItem search_item {
		get { return _search_item; }
		set {
			_search_item = value;

			title.label = search_item.get_title ();
		}
	}
}
