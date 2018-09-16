// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-header-bar.ui")]
private class Games.CollectionHeaderBar : Gtk.HeaderBar {
	public bool search_mode { get; set; }

	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		get { return _viewstack; }
		set {
			_viewstack = value;
			view_switcher.stack = _viewstack;
		}
	}

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;
			search.sensitive = !_is_collection_empty;
			update_title (Gtk.StackTransitionType.CROSSFADE);
		}
	}

	private bool _is_narrow;
	public bool is_narrow {
		get { return _is_narrow; }
		set {
			_is_narrow = value;
			update_title (Gtk.StackTransitionType.SLIDE_UP_DOWN);
		}
	}

	[GtkChild]
	private Gtk.Stack title_stack;
	[GtkChild]
	private Gtk.StackSwitcher view_switcher;
	[GtkChild]
	private Gtk.ToggleButton search;
	private Binding search_binding;

	construct {
		search_binding = bind_property ("search-mode", search, "active",
		                                BindingFlags.BIDIRECTIONAL);
	}

	private void update_title (Gtk.StackTransitionType transition) {
		if (is_collection_empty || is_narrow)
			title_stack.set_visible_child_full ("title", transition);
		else
			title_stack.set_visible_child_full ("view_switcher", transition);
	}
}
