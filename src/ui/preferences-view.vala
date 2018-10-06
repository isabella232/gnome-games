// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-view.ui")]
private class Games.PreferencesView : Gtk.Stack, ApplicationView {
	public signal void back ();

	[GtkChild]
	private Gtk.Stack titlebar_stack;
	[GtkChild]
	private Gtk.Box titlebar_box;
	[GtkChild]
	private Gtk.HeaderBar right_header_bar;
	[GtkChild]
	private Gtk.Box content_box;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Gtk.Button back_button;

	public bool selection_mode { get; set; }

	public bool is_view_active { get; set; }

	public bool show_back_button { get; set; }

	public Gtk.Widget titlebar {
		get {
			return titlebar_stack;
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
				visible_child = content_box;
				titlebar_stack.visible_child = titlebar_box;
				selection_mode_binding.unbind ();
			}

			if (value != null) {
				var header_bar = value.header_bar;

				add (value);
				visible_child = value;

				selection_mode_binding = value.bind_property ("request-selection-mode",
				                                              this, "selection-mode",
				                                              BindingFlags.SYNC_CREATE);

				titlebar_stack.add (header_bar);
				titlebar_stack.visible_child = header_bar;
			}

			_subpage = value;
		}
	}

	// The previous subpage instance must be kept around during the transition
	private PreferencesSubpage previous_subpage;

	private Binding subpage_binding;
	private Binding selection_mode_binding;
	private Binding back_button_binding;

	public PreferencesView () {
		stack.notify["visible-child-name"].connect (visible_child_changed);
		back_button_binding = bind_property ("show-back-button", back_button,
		                                     "visible", BindingFlags.SYNC_CREATE);
		visible_child_changed ();
	}

	private void visible_child_changed () {
		var page = stack.visible_child as PreferencesPage;
		if (page == null) {
			right_header_bar.title = "";
			subpage = null;

			return;
		}

		var title = "";
		stack.child_get (page, "title", out title, null);
		right_header_bar.title = title;

		subpage_binding = page.bind_property ("subpage", this, "subpage",
		                                      BindingFlags.SYNC_CREATE);
	}

	[GtkCallback]
	public void subpage_transition_finished (Object object, ParamSpec param) {
		if (transition_running || previous_subpage == null)
			return;

		remove (previous_subpage);
		titlebar_stack.remove (previous_subpage.header_bar);
		previous_subpage = null;
	}

	[GtkCallback]
	private void on_back_clicked () {
		back ();
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		return false;
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return false;
	}
}
