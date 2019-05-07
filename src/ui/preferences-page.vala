// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page.ui")]
private class Games.PreferencesPage : Gtk.Bin, Gtk.Buildable {
	public PreferencesSubpage subpage { get; protected set; }
	public string title { get; construct set; }


	[GtkChild]
	private Gtk.Label error_label;
	[GtkChild]
	private Gtk.Revealer error_notification_revealer;
	[GtkChild]
	private Gtk.Box box;

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
