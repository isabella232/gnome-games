// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-header-bar.ui")]
private class Games.CollectionHeaderBar : Gtk.HeaderBar {
	public bool search_mode { get; set; }
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
		set {
			_viewstack = value;
			view_switcher.set_stack (_viewstack);
		}
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			if (_is_collection_empty)
				title_stack.visible_child = empty_title;
			else
				title_stack.visible_child = view_switcher;
			search.sensitive = !_is_collection_empty;
		}
	}

	[GtkChild]
	private Gtk.Stack title_stack;
	[GtkChild]
	private Gtk.Label empty_title;
	[GtkChild]
	private Gtk.StackSwitcher view_switcher;
	[GtkChild]
	private Gtk.ToggleButton search;
	private Binding search_binding;

	construct {
		search_binding = bind_property ("search-mode", search, "active",
		                                BindingFlags.BIDIRECTIONAL);
	}
}
