// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DevelopersView : SidebarView {
	// This is a List because Developer objects are mutable,
	// and can't be stored in a GenericSet without breaking.
	private List<Developer> shown_developers;
	private List<Developer> all_developers;

	construct {
		shown_developers = new List<Developer> ();
		all_developers = new List<Developer> ();
	}

	protected override void game_added (Game game) {
		var developer = game.get_developer ();

		all_developers.append (developer);
		show_developer (developer);
		developer.changed.connect (invalidate_developer);
	}

	private bool show_developer (Developer developer) {
		var not_shown = shown_developers.find_custom (developer, Developer.compare) == null;
		if (not_shown) {
			shown_developers.append (developer);
			list_box.add (new DeveloperListItem (developer));

			var selected_row = list_box.get_selected_row ();
			if (selected_row != null)
				invalidate (selected_row);
		}

		return not_shown;
	}

	private void hide_developer (Developer developer) {
		Gtk.ListBoxRow? first_occurence = null;

		foreach (var item in list_box.get_children ()) {
			var row = item as Gtk.ListBoxRow;
			var list_item = row.get_child () as DeveloperListItem;

			if (Developer.equal (list_item.developer, developer)) {
				if (first_occurence != null) {
					if (row == list_box.get_selected_row ())
						list_box.select_row (first_occurence);

					row.destroy ();

					break;
				}
				else {
					first_occurence = row;
					first_occurence.changed ();
				}
			}
		}
	}

	private void invalidate_developer (Developer developer) {
		if (!show_developer (developer)) {
			// If already shown, this developer's list item gets updated,
			// hence try to show developers that are now not represented,
			// and hide the developers that are now multiply represented.
			all_developers.foreach ((item) => show_developer (item));
			hide_developer (developer);
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

		return DeveloperListItem.compare (item1, item2);
	}
}
