// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/fullscreen-box.ui")]
private class Games.FullscreenBox : Gtk.EventBox, Gtk.Buildable {
	private const uint INACTIVITY_TIME_MILLISECONDS = 3000;
	private const int SHOW_HEADERBAR_DISTANCE = 5;

	private bool _is_fullscreen;
	public bool is_fullscreen {
		get { return _is_fullscreen; }
		set {
			_is_fullscreen = value;

			if (!autohide)
				return;

			if (is_fullscreen) {
				show_ui ();
				on_cursor_moved ();
			}
			else
				on_restore ();
		}
	}

	public bool overlay { get; set; }

	private bool _autohide = true;
	public bool autohide {
		get { return _autohide; }
		set {
			if (autohide == value)
				return;

			_autohide = value;

			if (value) {
				show_ui ();
				on_cursor_moved ();
			}
			else {
				// Disable timers
				if (ui_timeout_id != -1) {
					Source.remove (ui_timeout_id);
					ui_timeout_id = -1;
				}

				if (cursor_timeout_id != -1) {
					Source.remove (cursor_timeout_id);
					cursor_timeout_id = -1;
				}

				titlebar_box.reveal_titlebar = true;
				show_cursor (true);
			}
		}
	}

	[GtkChild]
	private unowned TitlebarBox titlebar_box;

	private uint ui_timeout_id;
	private uint cursor_timeout_id;

	construct {
		ui_timeout_id = -1;
		cursor_timeout_id = -1;
	}

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		if (titlebar_box == null) {
			add (widget);
			return;
		}

		if (type == "titlebar")
			titlebar_box.titlebar = widget;
		else
			titlebar_box.add (widget);
	}

	[GtkCallback]
	private bool on_motion_event (Gdk.EventMotion event) {
		if (!autohide)
			return false;

		if (event.y_root <= SHOW_HEADERBAR_DISTANCE)
			show_ui ();

		on_cursor_moved ();

		return false;
	}

	private void show_ui () {
		if (ui_timeout_id != -1) {
			Source.remove (ui_timeout_id);
			ui_timeout_id = -1;
		}

		if (!is_fullscreen)
			return;

		ui_timeout_id = Timeout.add (INACTIVITY_TIME_MILLISECONDS, hide_ui);
		titlebar_box.reveal_titlebar = true;
	}

	private bool hide_ui () {
		ui_timeout_id = -1;

		if (!is_fullscreen)
			return false;

		titlebar_box.reveal_titlebar = false;
		titlebar_box.grab_focus ();

		return false;
	}

	private void on_cursor_moved () {
		if (cursor_timeout_id != -1) {
			Source.remove (cursor_timeout_id);
			cursor_timeout_id = -1;
		}

		cursor_timeout_id = Timeout.add (INACTIVITY_TIME_MILLISECONDS, on_inactivity);
		show_cursor (true);
	}

	private bool on_inactivity () {
		cursor_timeout_id = -1;

		show_cursor (false);

		return false;
	}

	private void on_restore () {
		if (ui_timeout_id != -1) {
			Source.remove (ui_timeout_id);
			ui_timeout_id = -1;
		}

		if (cursor_timeout_id != -1) {
			Source.remove (cursor_timeout_id);
			cursor_timeout_id = -1;
		}

		// This is needed when restoring via a keyboard shortcut when the
		// titlebar is concealed.
		titlebar_box.reveal_titlebar = true;

		on_cursor_moved ();
	}

	private void show_cursor (bool show) {
		var window = get_window ();
		if (window == null)
			return;

		if ((show && window.cursor == null) ||
		    (!show && window.cursor != null))
			return;

		if (!show) {
			var display = window.get_display ();
			window.cursor = new Gdk.Cursor.from_name (display, "none");
		}
		else
			window.cursor = null;
	}
}
