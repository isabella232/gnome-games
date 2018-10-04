// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-view.ui")]
private class Games.CollectionView: Gtk.Bin, ApplicationView {
	public signal void game_activated (Game game);

	[GtkChild]
	public CollectionBox box;
	[GtkChild]
	public CollectionHeaderBar header_bar;

	public Gtk.Widget titlebar {
		get { return header_bar; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;
		}
	}

	public ApplicationWindow window { get; construct set; }

	private ListModel _collection;
	public ListModel collection {
		get { return _collection; }
		construct set {
			_collection = value;
			box.collection = _collection;
		}
	}

	construct {
		header_bar.viewstack = box.viewstack;
	}

	public CollectionView (ListModel collection) {
		box.collection = collection;
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		return false;
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return false;
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}
}
