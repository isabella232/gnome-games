// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/savestates-list.ui")]
private class Games.SavestatesList : Gtk.Box {
	public signal void hidden ();

	[GtkChild]
	private Gtk.Revealer revealer;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private Gtk.ListBoxRow new_savestate_row;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;
	[GtkChild]
	private Gtk.Button delete_btn;
	[GtkChild]
	private Gtk.Button rename_btn;

	[GtkChild]
	private Gtk.Popover rename_popover;
	[GtkChild]
	private Gtk.Entry rename_entry;
	[GtkChild]
	private Gtk.Button rename_popover_btn;
	[GtkChild]
	private Gtk.Label rename_error_label;

	private Savestate selected_savestate;

	private SavestatesListState _state;
	public SavestatesListState state {
		get { return _state; }
		set {
			if (_state != null)
				_state.notify["is-revealed"].disconnect (on_revealed_changed);

			_state = value;

			if (value != null)
				value.notify["is-revealed"].connect (on_revealed_changed);
		}
	}

	public Runner runner { get; set; }

	construct {
		list_box.set_header_func (update_header);
	}

	public void set_margin (int margin) {
		scrolled_window.margin_top = margin;
	}

	[GtkCallback]
	private void on_move_cursor () {
		var row = list_box.get_selected_row ();

		if (row != null && row is SavestateListBoxRow) {
			var savestate_row = row as SavestateListBoxRow;
			var savestate = savestate_row.savestate;

			if (savestate != selected_savestate)
				select_savestate_row (row);
		}
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow activated_row) {
		if (activated_row == new_savestate_row) {
			var savestate = runner.try_create_savestate (false);

			if (savestate != null) {
				var savestate_row = new SavestateListBoxRow (savestate);

				list_box.insert (savestate_row, 1);
				select_savestate_row (savestate_row);
				savestate_row.reveal ();
			}
			else {
				// Savestate creation failed
				select_savestate_row (list_box.get_row_at_index (1));

				// TODO: Perhaps we should warn the user that the creation of
				// the savestate failed via an in-app notification ?
			}
		} else
			select_savestate_row (activated_row);
	}

	private void populate_list_box () {
		// Remove current savestate rows
		var list_rows =  list_box.get_children ();
		foreach (var row in list_rows) {
			if (row != new_savestate_row)
				list_box.remove (row);
		}

		if (runner == null)
			return;

		var savestates = _runner.get_savestates ();
		foreach (var savestate in savestates) {
			var list_row = new SavestateListBoxRow (savestate);
			// Reveal it early so that it doesn't animate
			list_row.reveal ();

			list_box.add (list_row);
		}
	}

	private void on_revealed_changed () {
		revealer.reveal_child = state.is_revealed;

		if (state.is_revealed) {
			runner.pause ();
			populate_list_box ();
			select_savestate_row (null);
		}
		// Runner isn't resumed here but after the revealer finishes the transition
	}

	[GtkCallback]
	private void on_revealer_transition_end () {
		if (!state.is_revealed)
			hidden ();
	}

	[GtkCallback]
	private void on_delete_clicked () {
		var selected_row = list_box.get_selected_row ();
		var selected_row_index = selected_row.get_index ();
		var savestate_row = selected_row as SavestateListBoxRow;
		var savestate = savestate_row.savestate;

		ensure_row_is_visible (selected_row);
		runner.delete_savestate (savestate);

		// Select and preview a new row
		var next_row_index = selected_row_index + 1;
		var new_selected_row = list_box.get_row_at_index (next_row_index);
		while (new_selected_row != null && !new_selected_row.selectable) {
			next_row_index++;
			new_selected_row = list_box.get_row_at_index (next_row_index);
		}

		if (new_selected_row == null) {
			// There are no more selectable rows after the selected row
			// Check if there are any selectable rows before the selected row

			var prev_row_index = selected_row_index - 1;
			new_selected_row = list_box.get_row_at_index (prev_row_index);
			while (prev_row_index > 1 && !new_selected_row.selectable) {
				prev_row_index--;
				new_selected_row = list_box.get_row_at_index (prev_row_index);
			}
		}

		if (new_selected_row != null && new_selected_row.selectable)
			select_savestate_row (new_selected_row);
		else
			select_savestate_row (null);

		savestate_row.remove_animated ();
	}

	[GtkCallback]
	private void on_rename_clicked () {
		var selected_row = list_box.get_selected_row ();

		ensure_row_is_visible (selected_row);

		rename_entry.text = selected_savestate.name;
		rename_popover.relative_to = selected_row;
		rename_popover.popup ();
	}

	// Adapted from gtklistbox.c, ensure_row_visible()
	private void ensure_row_is_visible (Gtk.ListBoxRow row) {
		Gtk.Allocation allocation;

		row.get_allocation (out allocation);
		var y = allocation.y;
		var height = allocation.height;

		scrolled_window.kinetic_scrolling = false;
		scrolled_window.vadjustment.clamp_page (y, y + height);
		scrolled_window.kinetic_scrolling = true;
	}

	[GtkCallback]
	private void on_rename_entry_activated () {
		if (check_rename_is_valid ())
			apply_rename ();
	}

	[GtkCallback]
	private void on_rename_entry_text_changed () {
		check_rename_is_valid ();
	}

	private bool check_rename_is_valid () {
		var entry_text = rename_entry.text.strip ();

		if (entry_text == _("Autosave") || entry_text == "") {
			rename_entry.get_style_context ().add_class ("error");
			rename_popover_btn.sensitive = false;
			rename_error_label.label = _("Invalid name");

			return false;
		}

		foreach (var list_child in list_box.get_children ()) {
			if (!(list_child is SavestateListBoxRow))
				continue; // Ignore the new savestate row;

			var savestate_row = list_child as SavestateListBoxRow;
			var savestate = savestate_row.savestate;

			if (savestate.is_automatic)
				continue;

			if (savestate.name == entry_text) {
				rename_entry.get_style_context ().add_class ("error");
				rename_popover_btn.sensitive = false;
				rename_error_label.label = _("A snapshot with this name already exists");

				return false;
			}
		}

		// All checks passed, rename operation is valid
		rename_entry.get_style_context ().remove_class ("error");
		rename_popover_btn.sensitive = true;
		rename_error_label.label = "";

		return true;
	}

	[GtkCallback]
	private void apply_rename () {
		var selected_row = list_box.get_selected_row ();
		var savestate_row = selected_row as SavestateListBoxRow;

		savestate_row.set_name (rename_entry.text.strip ());
		rename_popover.popdown ();
	}

	private void update_header (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
		if (before != null && row.get_header () == null) {
			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			row.set_header (separator);
		}
	}

	private SimpleAction lookup_action (string name) {
		var group = get_action_group ("display") as ActionMap;
		assert (group != null);

		var action = group.lookup_action (name);
		assert (action is SimpleAction);

		return action as SimpleAction;
	}

	private void select_savestate_row (Gtk.ListBoxRow? row) {
		list_box.select_row (row);

		if (row == null) {
			runner.preview_current_state ();
			selected_savestate = null;
			lookup_action ("load-snapshot").set_enabled (false);
		}
		else {
			row.grab_focus ();

			if (!(row is SavestateListBoxRow))
				return;

			var savestate_row = row as SavestateListBoxRow;
			var savestate = savestate_row.savestate;

			if (savestate == selected_savestate) {
				lookup_action ("load-snapshot").activate (null);
				return;
			}

			runner.preview_savestate (savestate);
			selected_savestate = savestate;
			lookup_action ("load-snapshot").set_enabled (true);
		}

		delete_btn.sensitive = (selected_savestate != null);
		rename_btn.sensitive = (selected_savestate != null &&
		                        !selected_savestate.is_automatic);
	}

	public bool on_key_press_event (uint keyval, Gdk.ModifierType state) {
		// FIXME: Move the other list shortcuts here

		if (keyval == Gdk.Key.Delete || keyval == Gdk.Key.KP_Delete) {
			on_delete_clicked ();
			return true;
		}

		return false;
	}
}
