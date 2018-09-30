// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PlatformsView : SidebarView {
	private GenericSet<Platform> platforms = new GenericSet<Platform> (Platform.hash, Platform.equal);

	protected override void game_added (Game game) {
		var platform = game.get_platform ();

		if (!platforms.contains (platform)) {
			platforms.add (platform);
			var platform_list_item = new PlatformListItem (platform);
			list_box.add (platform_list_item);
		}
	}

	protected override void invalidate (Gtk.ListBoxRow row_item) {
		var row = row_item.get_child () as PlatformListItem;
		var platform = row.platform;
		collection_view.filtering_platform = platform;
	}

	protected override int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = row1.get_child () as PlatformListItem;
		var item2 = row2.get_child () as PlatformListItem;

		return PlatformListItem.compare (item1, item2);
	}
}
