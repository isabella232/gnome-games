// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DevelopersView : SidebarView {
	private GenericSet<Developer> shown_developers;

	private uint unknown_games;
	private DeveloperListItem unknown_item;

	construct {
		shown_developers = new GenericSet<Developer> (Developer.hash, Developer.equal);
		unknown_games = 0;
	}

	protected override void game_added (Game game) {
		var developer = game.get_developer ();

		if (developer.has_loaded && developer.get_developer () != "")
			show_developer (developer);
		else {
			show_unknown ();
			developer.notify["has-loaded"].connect (invalidate_developer);
		}
	}

	private void show_developer (Developer developer) {
		var shown = shown_developers.contains (developer);
		if (!shown) {
			shown_developers.add (developer);
			list_box.add (new DeveloperListItem (developer));

			var selected_row = list_box.get_selected_row ();
			if (selected_row != null)
				invalidate (selected_row);
		}
	}

	private void show_unknown () {
		unknown_games++;

		if (unknown_item != null)
			return;

		var developer = new DummyDeveloper ();
		shown_developers.add (developer);

		unknown_item = new DeveloperListItem (developer);

		list_box.add (unknown_item);
	}

	private void invalidate_developer (Object object, ParamSpec param) {
		var developer = object as Developer;

		if (developer.has_loaded)
			show_developer (developer);

		unknown_games--;
		collection_view.invalidate_filter ();

		if (unknown_games == 0) {
			list_box.remove (unknown_item);
			unknown_item = null;
			select_default_row ();
		}
	}

	protected override void invalidate (Gtk.ListBoxRow row_item) {
		var row = row_item as DeveloperListItem;
		var developer = row.developer;
		collection_view.filtering_developer = developer;
	}

	protected override int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
		var item1 = row1 as DeveloperListItem;
		var item2 = row2 as DeveloperListItem;

		return DeveloperListItem.compare (item1, item2);
	}
}
