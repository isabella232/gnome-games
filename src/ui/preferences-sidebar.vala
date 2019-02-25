// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-sidebar.ui")]
private class Games.PreferencesSidebar : Gtk.Bin {
	private ulong child_added_id;

	private Gtk.Stack _stack;
	public Gtk.Stack stack {
		get {
			return _stack;
		}
		set {
			if (_stack != null) {
				clear_sidebar ();
				stack.disconnect (child_added_id);
				_stack = null;
			}

			_stack = value;

			if (_stack != null)
				populate_sidebar ();

			child_added_id = stack.add.connect (add_child);

			queue_resize ();
		}
	}

	private bool _show_selection;
	public bool show_selection {
		get { return _show_selection; }
		set {
			_show_selection = value;

			if (_show_selection)
				list.selection_mode = Gtk.SelectionMode.SINGLE;
			else
				list.selection_mode = Gtk.SelectionMode.NONE;

			if (stack != null)
				select_current_row ();
		}
	}

	public signal void row_selected ();

	[GtkChild]
	private Gtk.ListBox list;
	private HashTable<PreferencesPage, PreferencesSidebarItem> rows;

	static construct {
		set_css_name ("stacksidebar");
	}

	construct {
		rows = new HashTable<PreferencesPage, PreferencesSidebarItem> (null, null);
		list.set_header_func (update_header);
		show_selection = true;
	}

	[GtkCallback]
	private void row_activated (Gtk.ListBox box, Gtk.ListBoxRow? row) {
		if (row == null)
			return;

		var item = row as PreferencesSidebarItem;
		var page = item.preferences_page;
		stack.visible_child = page;

		row_selected ();
	}

	private void add_child (Gtk.Widget widget) {
		var page = widget as PreferencesPage;

		var row = new PreferencesSidebarItem (page);

		rows[page] = row;
		list.add (row);
	}

	private void populate_sidebar () {
		stack.foreach (add_child);

		select_current_row ();
	}

	private void clear_sidebar () {
		foreach (var page in rows.get_keys ()) {
			var row = rows[page];

			list.remove (row);
			rows.remove (page);
		}
	}

	private void select_current_row () {
		if (!show_selection)
			return;

		var page = stack.visible_child as PreferencesPage;

		var row = rows[page];

		if (row != null)
			list.select_row (row);
	}

	private void update_header (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
		if (before != null && row.get_header () == null) {
			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			row.set_header (separator);
		}
	}
}
