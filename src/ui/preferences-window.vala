// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-window.ui")]
private class Games.PreferencesWindow : Gtk.Window {
	[GtkChild]
	private Hdy.TitleBar titlebar;
	[GtkChild]
	private Gtk.Stack titlebar_stack;
	[GtkChild]
	private Gtk.Box titlebar_box;
	[GtkChild]
	private Gtk.HeaderBar left_header_bar;
	[GtkChild]
	private Gtk.Separator header_separator;
	[GtkChild]
	private Gtk.Stack main_stack;
	[GtkChild]
	private Gtk.Box content_box;
	[GtkChild]
	private Gtk.StackSidebar sidebar;
	[GtkChild]
	private Gtk.Separator separator;
	[GtkChild]
	private Gtk.Stack stack;

	private Gtk.HeaderBar _right_header_bar;
	public Gtk.HeaderBar right_header_bar {
		get { return _right_header_bar; }
		set {
			if (_right_header_bar != null)
				titlebar_box.remove (_right_header_bar);
			if (value != null) {
				titlebar_box.pack_end (value);
				value.show_close_button = !immersive_mode;
			}
			_right_header_bar = value;
		}
	}

	private bool _immersive_mode;
	public bool immersive_mode {
		get { return _immersive_mode; }
		set {
			titlebar.selection_mode = value;
			header_separator.visible = !value;
			left_header_bar.visible = !value;
			separator.visible = !value;
			sidebar.visible = !value;
			if (right_header_bar != null)
				right_header_bar.show_close_button = !value;

			_immersive_mode = value;
		}
	}

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
			}

			_subpage = value;
		}
	}

	// The previous subpage instance must be kept around during the transition
	private PreferencesSubpage previous_subpage;

	private Binding right_header_bar_binding;
	private Binding immersive_mode_binding;
	private Binding subpage_binding;
	private Binding selection_mode_binding;

	public PreferencesWindow () {
		stack.foreach ((child) => {
			var page = child as PreferencesPage;
			stack.notify["visible-child-name"].connect (page.visible_page_changed);
		});
		stack.notify["visible-child-name"].connect (visible_child_changed);
		visible_child_changed ();
	}

	private void visible_child_changed () {
		var page = stack.visible_child as PreferencesPage;
		if (page == null) {
			right_header_bar = null;
			subpage = null;

			return;
		}
		right_header_bar_binding = page.bind_property ("header-bar", this, "right_header_bar",
		                                               BindingFlags.SYNC_CREATE);
		immersive_mode_binding = page.bind_property ("immersive-mode", this, "immersive-mode",
		                                             BindingFlags.SYNC_CREATE);
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
}
