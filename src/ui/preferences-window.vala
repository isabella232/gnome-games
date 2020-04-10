// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Gtk.Window {
	[GtkChild]
	private Hdy.Leaflet titlebar_leaflet;
	[GtkChild]
	private Gtk.HeaderBar right_header_bar;
	[GtkChild]
	private Hdy.Deck content_deck;
	[GtkChild]
	private Hdy.Leaflet content_leaflet;
	[GtkChild]
	private Gtk.Box content_subpage_box;
	[GtkChild]
	private PreferencesSidebar sidebar;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Hdy.HeaderGroup header_group;
	[GtkChild]
	private Gtk.Button page_back_button;
	[GtkChild]
	private Gtk.Button window_back_button;

	private PreferencesSubpage _subpage;
	public PreferencesSubpage subpage {
		get { return _subpage; }
		set {
			if (subpage == value)
				return;

			if (subpage != null) {
				content_deck.navigate (Hdy.NavigationDirection.BACK);
				swipe_back_binding.unbind ();
			}

			if (value != null) {
				content_subpage_box.add (value);

				swipe_back_binding = value.bind_property ("allow-back",
				                                          content_deck, "can-swipe-back",
				                                          BindingFlags.SYNC_CREATE);

				content_deck.navigate (Hdy.NavigationDirection.FORWARD);
				content_leaflet.navigate (Hdy.NavigationDirection.FORWARD);
			}

			_subpage = value;
		}
	}

	private Binding subpage_binding;
	private Binding swipe_back_binding;

	construct {
		update_ui ();
	}

	[GtkCallback]
	private void sidebar_row_selected () {
		content_leaflet.navigate (Hdy.NavigationDirection.FORWARD);

		update_ui ();
	}

	private void update_ui () {
		var page = stack.visible_child as PreferencesPage;

		if (subpage_binding != null) {
			subpage_binding.unbind ();
			subpage_binding = null;
		}

		if (page == null) {
			right_header_bar.title = "";
			subpage = null;

			return;
		}

		right_header_bar.title = page.title;

		subpage_binding = page.bind_property ("subpage", this, "subpage",
		                                      BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
	}

	private void remove_subpage () {
		foreach (var child in content_subpage_box.get_children ())
			content_subpage_box.remove (child);

		subpage = null;
	}

	[GtkCallback]
	public void subpage_transition_finished (Object object, ParamSpec param) {
		if (content_deck.transition_running ||
		    content_deck.visible_child != content_leaflet)
			return;

		remove_subpage ();
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (content_deck.transition_running || subpage == null)
			return;

		remove_subpage ();
	}

	[GtkCallback]
	private void on_back_clicked () {
		if (!content_leaflet.navigate (Hdy.NavigationDirection.BACK))
			close ();
	}

	[GtkCallback]
	private void on_folded_changed () {
		var folded = content_leaflet.folded;

		update_header_group ();
		page_back_button.visible = folded;
		window_back_button.visible = folded;
		sidebar.show_selection = !folded;

		if (folded)
			stack.transition_type = Gtk.StackTransitionType.NONE;
		else
			stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
	}

	[GtkCallback]
	private void update_header_group () {
		var folded = content_leaflet.folded;
		var visible_header_bar = titlebar_leaflet.visible_child as Gtk.HeaderBar;

		if (folded)
			header_group.focus = visible_header_bar;
		else
			header_group.focus = null;
	}
}
