// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/fullscreen-box.ui")]
private class Games.FullscreenBox : Gtk.EventBox, Gtk.Buildable {
	private const uint INACTIVITY_TIME_MILLISECONDS = 3000;
	private const int SHOW_HEADERBAR_DISTANCE = 5;

	public bool is_fullscreen { get; set; }

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
	private Binding visible_binding;
	private Binding fullscreen_binding;

	private uint ui_timeout_id;
	private uint cursor_timeout_id;

	construct {
		visible_binding = bind_property ("is-fullscreen", header_bar_revealer,
		                                 "visible", BindingFlags.BIDIRECTIONAL);
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
	private void on_fullscreen_changed () {
		if (is_fullscreen) {
			show_ui ();
			on_cursor_moved ();
		}
		else
			on_restore ();
	}

	[GtkCallback]
	private bool on_motion_event (Gdk.EventMotion event) {
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
