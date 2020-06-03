// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Hdy.Window {
	[GtkChild]
	private Hdy.Deck deck;
	[GtkChild]
	private Gtk.Box main_box;
	[GtkChild]
	private Gtk.Box subpage_box;

	private PreferencesSubpage subpage;
	private Binding swipe_back_binding;

	[GtkCallback]
	public void try_remove_subpage () {
		if (deck.transition_running ||
		    deck.visible_child != main_box ||
		    subpage == null)
			return;

		subpage_box.remove (subpage);

		subpage = null;
	}

	public void open_subpage (PreferencesSubpage subpage) {
		if (this.subpage != null)
			return;

		this.subpage = subpage;

		swipe_back_binding = subpage.bind_property ("allow-back", deck,
		                                            "can-swipe-back",
		                                            BindingFlags.SYNC_CREATE);

		subpage_box.add (subpage);

		subpage.back.connect (() => {
			deck.navigate (Hdy.NavigationDirection.BACK);
			swipe_back_binding.unbind ();
		});

		deck.navigate (Hdy.NavigationDirection.FORWARD);
	}
}
