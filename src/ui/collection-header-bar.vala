// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-header-bar.ui")]
private class Games.CollectionHeaderBar : Gtk.HeaderBar {
	public bool search_mode { set; get; }
	private Gtk.Stack _viewstack;
	public Gtk.Stack viewstack {
		set {
			_viewstack = value;
			view_switcher.set_stack (_viewstack);
		}
		get { return _viewstack; }
	}

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
