// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/savestates-list.ui")]
private class Games.SavestatesList : Gtk.Box {
	[GtkChild]
	private Gtk.Revealer revealer;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private Gtk.ListBoxRow new_savestate_row;
	[GtkChild]
	private Gtk.ScrolledWindow scrolled_window;

	public bool is_revealed {
		get { return revealer.reveal_child; }
		set { revealer.reveal_child = value; }
	}

	private SavestatesListState _state;
	public SavestatesListState state {
		get { return _state; }
		set {
			if (_state != null)
				_state.notify["is-revealed"].disconnect (on_state_changed);

			_state = value;

			if (value != null) {
				value.notify["is-revealed"].connect (on_state_changed);
				value.load_clicked.connect (on_load_clicked);
				value.delete_clicked.connect (on_delete_clicked);
			}
		}
	}

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			_runner = value;

			// Remove current savestate rows
			var list_rows =  list_box.get_children ();
			foreach (var row in list_rows) {
				if (row != new_savestate_row)
					list_box.remove (row);
			}

			if (value == null)
				return;

			// value != null
			var savestates = _runner.get_savestates ();
			foreach (var savestate in savestates) {
				var list_row = new SavestateListBoxRow (savestate);

				list_box.add (list_row);
			}
		}
	}

	construct {
		list_box.set_header_func (update_header);
	}

	public void set_fullscreen_margin (int margin) {
		scrolled_window.margin_top = margin;
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow activated_row) {
		if (activated_row == new_savestate_row) {
			var savestate = runner.try_create_savestate (false);

			if (savestate != null) {
				var savestate_row = new SavestateListBoxRow (savestate);

				list_box.insert (savestate_row, 1);
				select_savestate_row (savestate_row);
			}
			else {
				// Savestate creation failed
				list_box.select_row (list_box.get_row_at_index (1));

				// TODO: Perhaps we should warn the user that the creation of
				// the savestate failed via an in-app notification ?
			}
		} else
			select_savestate_row (activated_row);
	}

	private void on_load_clicked () {
		if (!try_runner_load_previewed_savestate ()) {
			// TODO: Here we could show a dialog with one button like
			// "Failed to load savestate [Ok]"
		}

		state.is_revealed = false;
	}

	private bool try_runner_load_previewed_savestate () {
		try {
			_runner.load_previewed_savestate ();
		}
		catch (Error e) {
			critical ("Failed to load savestate: %s", e.message);

			return false;
		}

		// Nothing went wrong
		return true;
	}

	private void on_state_changed () {
		revealer.reveal_child = state.is_revealed;

		if (state.is_revealed) {
			runner.capture_current_state_pixbuf ();
			runner.pause ();

			select_savestate_row (null);
		}
		else
			runner.resume ();
	}

	private void on_delete_clicked () {
		var selected_row = list_box.get_selected_row ();
		var selected_row_index = selected_row.get_index ();
		var savestate_row = selected_row as SavestateListBoxRow;
		var savestate = savestate_row.savestate;

		runner.delete_savestate (savestate);
		list_box.remove (selected_row);

		// Select and preview a new row
		var next_row = list_box.get_row_at_index (selected_row_index);

		if (next_row == null) { // The last row in the list has been deleted
			var nr_rows = list_box.get_children ().length ();

			if (nr_rows == 1) {
				// The only remaining row in the list is the create savestate one
				select_savestate_row (null);
			}
			else {
				// The last row of the list has been deleted but there are still
				// rows remaining in the list
				var last_row = list_box.get_row_at_index (selected_row_index - 1);
				select_savestate_row (last_row);
			}

			return;
		}

		select_savestate_row (next_row);
	}

	private void update_header (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
		if (before != null && row.get_header () == null) {
			var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
			row.set_header (separator);
		}
	}

	private void select_savestate_row (Gtk.ListBoxRow? row) {
		if (row == null) {
			list_box.select_row (null);
			runner.preview_current_state ();
			state.selected_savestate = null;
		}
		else {
			var savestate_row = row as SavestateListBoxRow;
			var savestate = savestate_row.savestate;

			list_box.select_row (row);
			runner.preview_savestate (savestate);
			state.selected_savestate = savestate;
		}
	}
}
