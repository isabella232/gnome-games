// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/sidebar-view.ui")]
private abstract class Games.SidebarView : Gtk.Box {
	public signal void game_activated (Game game);

	public string filtering_text {
		set { collection_view.filtering_text = value; }
	}

	private ListModel _model;
	public ListModel model {
		set {
			_model = value;
			collection_view.model = _model;
			model.items_changed.connect (on_model_changed);
		}
		get { return _model; }
	}


	[GtkChild]
	protected CollectionIconView collection_view;

	[GtkChild]
	protected Gtk.ListBox list_box;

	construct {
		list_box.set_sort_func (sort_rows);

		collection_view.game_activated.connect ((game) => {
			game_activated (game);
		 });
	}

	protected abstract void game_added (Game game);
	protected abstract void invalidate (Gtk.ListBoxRow row_item);
	protected abstract int sort_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2);

	[GtkCallback]
	private void on_list_box_row_selected (Gtk.ListBoxRow row_item) {
		list_box.select_row (row_item);
		invalidate (row_item);
		collection_view.reset_scroll_position ();
	}

	private void on_model_changed (uint position, uint removed, uint added) {
		// FIXME: currently games are never removed, update this function if
		// necessary.
		assert (removed == 0);

		for (uint i = position ; i < position + added ; i++) {
			var game = model.get_item (i) as Game;
			game_added (game);
		}
	}

	public void select_default_row () {
		var row = list_box.get_row_at_index (0) as Gtk.ListBoxRow;

		if (row == null)
			return;

		on_list_box_row_selected (row);
	}
}
