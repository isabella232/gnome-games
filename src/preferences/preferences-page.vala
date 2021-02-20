// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/preferences/preferences-page.ui")]
private class Games.PreferencesPage : Gtk.Bin, Gtk.Buildable {
	public PreferencesWindow window { get; construct; }

	[GtkChild]
	private unowned Gtk.Label error_label;
	[GtkChild]
	private unowned Gtk.Revealer error_notification_revealer;
	[GtkChild]
	private unowned Gtk.Box box;

	[GtkCallback]
	private void on_error_notification_closed () {
		error_notification_revealer.reveal_child = false;
	}

	protected void show_error_message (string error_message) {
		error_label.label = error_message;
		error_notification_revealer.reveal_child = true;
	}

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		if (box != null)
			box.add (widget);
		else
			add (widget);
	}
}
