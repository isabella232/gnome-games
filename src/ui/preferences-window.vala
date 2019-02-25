// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Gtk.Window {
	[GtkChild]
	private Hdy.TitleBar titlebar;
	[GtkChild]
	private Gtk.Stack titlebar_stack;
	[GtkChild]
	private Hdy.Leaflet titlebar_box;
	[GtkChild]
	private Gtk.HeaderBar left_header_bar;
	[GtkChild]
	private Gtk.HeaderBar right_header_bar;
	[GtkChild]
	private Gtk.Stack main_stack;
	[GtkChild]
	private Hdy.Leaflet content_box;
	[GtkChild]
	private PreferencesSidebar sidebar;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Hdy.HeaderGroup header_group;

	[GtkChild]
	private Gtk.Button back_button;

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
				selection_mode_binding.unbind ();
			}

			if (value != null) {
				var header_bar = value.header_bar;

				main_stack.add (value);
				main_stack.visible_child = value;

				selection_mode_binding = value.bind_property ("request-selection-mode",
				                                              titlebar, "selection-mode",
				                                              BindingFlags.SYNC_CREATE);

				titlebar_stack.add (header_bar);
				titlebar_stack.visible_child = header_bar;

				content_box.visible_child = stack;
				titlebar_box.visible_child = right_header_bar;
			}

			_subpage = value;
		}
	}

	// The previous subpage instance must be kept around during the transition
	private PreferencesSubpage previous_subpage;

	private Binding subpage_binding;
	private Binding selection_mode_binding;

	construct {
		update_ui ();
	}

	[GtkCallback]
	private void sidebar_row_selected () {
		content_box.visible_child = stack;
		titlebar_box.visible_child = right_header_bar;
		update_header_group ();

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
		content_box.visible_child = sidebar;
		titlebar_box.visible_child = left_header_bar;
		update_header_group ();
	}

	[GtkCallback]
	private void on_folded_changed (Object object, ParamSpec paramSpec) {
		var folded = content_box.folded;

		update_header_group ();
		back_button.visible = folded;
		sidebar.show_selection = !folded;

		if (folded)
			stack.transition_type = Gtk.StackTransitionType.NONE;
		else
			stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
	}

	private void update_header_group () {
		var folded = content_box.folded;
		var visible_header_bar = titlebar_box.visible_child as Gtk.HeaderBar;

		if (folded)
			header_group.focus = visible_header_bar;
		else
			header_group.focus = null;
	}
}
