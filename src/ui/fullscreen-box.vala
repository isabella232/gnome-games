// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/fullscreen-box.ui")]
private class Games.FullscreenBox : Gtk.EventBox, Gtk.Buildable {
	private const uint INACTIVITY_TIME_MILLISECONDS = 2000;

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

	private uint timeout_id;

	construct {
		visible_binding = bind_property ("is-fullscreen", header_bar_revealer,
		                                 "visible", BindingFlags.BIDIRECTIONAL);
		timeout_id = -1;
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
		if (is_fullscreen)
			on_activity ();
		else
			on_restore ();
	}

	[GtkCallback]
	private bool on_motion_event (Gdk.EventMotion event) {
		on_activity ();

		return false;
	}

	private void on_activity () {
		if (timeout_id != -1) {
			Source.remove (timeout_id);
			timeout_id = -1;
		}

		if (!is_fullscreen)
			return;

		timeout_id = Timeout.add (INACTIVITY_TIME_MILLISECONDS, on_inactivity);
		header_bar_revealer.reveal_child = true;
		show_cursor (true);
	}

	private bool on_inactivity () {
		timeout_id = -1;

		if (!is_fullscreen)
			return false;

		header_bar_revealer.reveal_child = false;
		show_cursor (false);
		overlay.grab_focus ();

		return false;
	}

	private void on_restore () {
		if (timeout_id != -1) {
			Source.remove (timeout_id);
			timeout_id = -1;
		}

		header_bar_revealer.reveal_child = false;
		show_cursor (true);
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
			window.cursor = new Gdk.Cursor.for_display (display, Gdk.CursorType.BLANK_CURSOR);
		}
		else
			window.cursor = null;
	}
}
