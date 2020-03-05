// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-header-bar.ui")]
private class Games.CollectionHeaderBar : Gtk.Bin {
	public bool search_mode { get; set; }
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
		set {
			if (viewstack_child_changed_id != 0) {
				viewstack.disconnect (viewstack_child_changed_id);
				viewstack_child_changed_id = 0;
			}

			_viewstack = value;
			view_switcher_title.stack = _viewstack;
		}
	}

	public bool is_collection_empty { get; set; }

	public bool is_folded { get; set; }
	public bool is_showing_bottom_bar { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }
	public Hdy.SwipeGroup swipe_group { get; construct; }

	[GtkChild]
	private Hdy.Deck deck;
	[GtkChild]
	private Hdy.HeaderBar header_bar;
	[GtkChild]
	private Hdy.HeaderBar subview_header_bar;
	[GtkChild]
	private Hdy.ViewSwitcherTitle view_switcher_title;

	private ulong viewstack_child_changed_id;

	public CollectionHeaderBar (Hdy.SwipeGroup swipe_group) {
		Object (swipe_group: swipe_group);
	}

	[GtkCallback]
	private void update_adaptive_state () {
		bool showing_title = view_switcher_title.title_visible;
		is_showing_bottom_bar = showing_title && !is_collection_empty;
	}

	[GtkCallback]
	private void on_subview_back_clicked () {
		back ();
	}

	[GtkCallback]
	private void on_folded_changed () {
		if (is_folded) {
			deck.visible_child = is_subview_open ? subview_header_bar : header_bar;
			swipe_group.add_swipeable (deck);
		} else {
			swipe_group.remove_swipeable (deck);
			deck.visible_child = header_bar;
		}
	}

	public bool back () {
		return deck.navigate (Hdy.NavigationDirection.BACK);
	}
}
