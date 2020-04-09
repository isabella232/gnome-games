// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.UiView : Object {
	public abstract Gtk.Widget content_box { get; }

	public abstract bool is_view_active { get; set; }

	public abstract bool on_button_pressed (Gdk.EventButton event);

	public abstract bool on_key_pressed (Gdk.EventKey event);

	public abstract bool gamepad_button_press_event (Manette.Event event);

	public abstract bool gamepad_button_release_event (Manette.Event event);

	public abstract bool gamepad_absolute_axis_event (Manette.Event event);
}
