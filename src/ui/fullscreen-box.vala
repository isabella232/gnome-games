// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/fullscreen-box.ui")]
private class Games.FullscreenBox : Gtk.Bin, Gtk.Buildable {
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

				header_bar_revealer.reveal_child = true;
				show_cursor (true);
			}
		}
	}

	private Gtk.Widget _header_bar;
	public Gtk.Widget header_bar {
		get { return _header_bar; }
		set {
			if (header_bar == value)
				return;

			if (fullscreen_binding != null) {
				fullscreen_binding.unbind ();
				fullscreen_binding = null;
			}

			_header_bar = value;

			if (header_bar != null)
				fullscreen_binding = bind_property ("is-fullscreen", header_bar,
					                                "is-fullscreen",
					                                BindingFlags.BIDIRECTIONAL);
		}
	}

	[GtkChild]
	private Gtk.Overlay overlay;
	[GtkChild]
	private Gtk.Revealer header_bar_revealer;
	private Binding fullscreen_binding;

	private uint ui_timeout_id;
	private uint cursor_timeout_id;

	construct {
		ui_timeout_id = -1;
		cursor_timeout_id = -1;
	}

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		if (overlay == null || header_bar_revealer == null) {
			add (widget);
			return;
		}

		if (type == "titlebar") {
			header_bar_revealer.add (widget);
			header_bar = widget;
		}
		else
			overlay.add (widget);
	}

	[GtkCallback]
	private void on_motion_event (Gtk.EventControllerMotion controller, double x, double y) {
		if (!autohide)
			return;

		if (y <= SHOW_HEADERBAR_DISTANCE)
			show_ui ();

		on_cursor_moved ();
	}

	private void show_ui () {
		if (ui_timeout_id != -1) {
			Source.remove (ui_timeout_id);
			ui_timeout_id = -1;
		}

		if (!is_fullscreen)
			return;

		ui_timeout_id = Timeout.add (INACTIVITY_TIME_MILLISECONDS, hide_ui);
		header_bar_revealer.reveal_child = true;
	}

	private bool hide_ui () {
		ui_timeout_id = -1;

		if (!is_fullscreen)
			return false;

		header_bar_revealer.reveal_child = false;
		overlay.grab_focus ();

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

		header_bar_revealer.reveal_child = false;
		on_cursor_moved ();
	}

	private void show_cursor (bool show) {
		if ((show && cursor == null) ||
		    (!show && cursor != null))
			return;

		if (!show)
			cursor = new Gdk.Cursor.from_name ("none", null);
		else
			cursor = null;
	}
}
