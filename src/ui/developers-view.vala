// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DevelopersView : SidebarView {
	private GenericSet<Developer> developers = new GenericSet<Developer> (Developer.hash, Developer.equal);
	private ulong developer_changed_id;

	private void invalidate_developer (Developer developer){
		if (!developers.contains (developer)) {
			developers.add (developer);
			var developer_list_item = new DeveloperListItem (developer);
			list_box.add (developer_list_item);
		}
	}

	protected override void game_added (Game game) {
		var developer = game.get_developer ();

		developer_changed_id = developer.changed.connect ((source) => {
			invalidate_developer (source);
		});

		// FIXME: Currently developers are fetched in sync and there is
		// a need to check non GriloDeveloper objects, update this function
		// if necessary.
		if (!(developer is GriloDeveloper)) {
			if (developers.contains (developer))
				return;

			developers.add (developer);
			var listbox_item = new DeveloperListItem (developer);
			list_box.add (listbox_item);
		}
	}

	protected override void invalidate (Gtk.ListBoxRow row_item) {
		var row = row_item.get_child () as DeveloperListItem;
		var developer = row.developer;
		collection_view.filtering_developer = developer;
	}

	protected override int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = row1.get_child () as DeveloperListItem;
		var item2 = row2.get_child () as DeveloperListItem;

		assert (item1 != null);
		assert (item2 != null);

		return item1.label.collate (item2.label);
	}
}
