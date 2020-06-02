// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Hdy.Window {
	[GtkChild]
	private Hdy.Deck content_deck;
	[GtkChild]
	private Gtk.Box main_box;
	[GtkChild]
	private Gtk.Box content_subpage_box;
	[GtkChild]
	private Gtk.Stack stack;

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
	private void update_ui () {
		var page = stack.visible_child as PreferencesPage;

		if (subpage_binding != null) {
			subpage_binding.unbind ();
			subpage_binding = null;
		}

		if (page == null) {
			subpage = null;

			return;
		}

		subpage_binding = page.bind_property ("subpage", this, "subpage",
		                                      BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
	}

	private void remove_subpage () {
		foreach (var child in content_subpage_box.get_children ())
			content_subpage_box.remove (child);

		subpage = null;
	}

	[GtkCallback]
	public void subpage_transition_finished () {
		if (content_deck.transition_running ||
		    content_deck.visible_child != main_box)
			return;

		remove_subpage ();
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (content_deck.transition_running || subpage == null)
			return;

		remove_subpage ();
	}
}
