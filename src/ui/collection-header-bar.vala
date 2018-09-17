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
			view_switcher.stack = _viewstack;
		}
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (value)
				title_squeezer.visible_child = empty_label;
			else
				title_squeezer.visible_child = view_switcher;
			update_adaptive_state ();
		}
	}

	public AdaptiveState adaptive_state { get; construct; }

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Gtk.HeaderBar header_bar;
	[GtkChild]
	private Gtk.HeaderBar subview_header_bar;
	[GtkChild]
	private Gtk.Stack title_squeezer;
	[GtkChild]
	private Gtk.StackSwitcher view_switcher;
	[GtkChild]
	private Gtk.Label empty_label;

	private ulong viewstack_child_changed_id;

	construct {
		adaptive_state.notify["is-folded"].connect (update_subview);
		adaptive_state.notify["is-subview-open"].connect (update_subview);
		adaptive_state.notify["subview-title"].connect (update_subview_title);
	}

	public CollectionHeaderBar (AdaptiveState adaptive_state) {
		Object (adaptive_state: adaptive_state);
	}

	[GtkCallback]
	private void on_squeezer_visible_child_changed () {
		update_adaptive_state ();
	}

	private void update_adaptive_state () {
		bool showing_title = title_squeezer.visible_child != view_switcher;
		adaptive_state.is_showing_bottom_bar = showing_title && !is_collection_empty;
	}

	private void update_subview () {
		if (adaptive_state.is_subview_open && adaptive_state.is_folded)
			stack.visible_child = subview_header_bar;
		else
			stack.visible_child = header_bar;
	}

	private void update_subview_title () {
		subview_header_bar.title = adaptive_state.subview_title;
	}

	[GtkCallback]
	private void on_subview_back_clicked () {
		adaptive_state.is_subview_open = false;
	}
}
