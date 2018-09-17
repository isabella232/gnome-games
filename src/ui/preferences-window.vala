// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Gtk.Window {
	[GtkChild]
	private Gtk.Stack titlebar_stack;
	[GtkChild]
	private Gtk.Box titlebar_box;
	[GtkChild]
	private Gtk.HeaderBar right_header_bar;
	[GtkChild]
	private Gtk.Stack main_stack;
	[GtkChild]
	private Gtk.Box content_box;
	[GtkChild]
	private Gtk.Stack stack;

	private PreferencesSubpage _subpage;
	public PreferencesSubpage subpage {
		get { return _subpage; }
		set {
			if (subpage == value)
				return;

			if (subpage != null) {
				previous_subpage = subpage;
				main_stack.visible_child = content_box;
				titlebar_stack.visible_child = titlebar_box;
			}

			if (value != null) {
				var header_bar = value.header_bar;

				main_stack.add (value);
				main_stack.visible_child = value;

				titlebar_stack.add (header_bar);
				titlebar_stack.visible_child = header_bar;
			}

			_subpage = value;
		}
	}

	// The previous subpage instance must be kept around during the transition
	private PreferencesSubpage previous_subpage;

	private Binding subpage_binding;

	construct {
		update_ui ();
	}

	[GtkCallback]
	private void sidebar_row_selected () {
		update_ui ();
	}

	private void update_ui () {
		var page = stack.visible_child as PreferencesPage;
		if (page == null) {
			right_header_bar.title = "";
			subpage = null;

			return;
		}

		right_header_bar.title = page.title;

		subpage_binding = page.bind_property ("subpage", this, "subpage",
		                                      BindingFlags.SYNC_CREATE);
	}

	[GtkCallback]
	public void subpage_transition_finished (Object object, ParamSpec param) {
		if (main_stack.transition_running || previous_subpage == null)
			return;

		main_stack.remove (previous_subpage);
		titlebar_stack.remove (previous_subpage.header_bar);
		previous_subpage = null;
	}

	[GtkCallback]
	private void on_back_clicked () {
	}
}
