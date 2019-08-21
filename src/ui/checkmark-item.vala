// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/checkmark-item.ui")]
private class Games.CheckmarkItem : Gtk.ListBoxRow {
	public bool checkmark_visible { get; set; }
	public string label { get; construct; }

	public CheckmarkItem (string label) {
		Object (label: label);
	}
}
