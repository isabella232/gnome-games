// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page.ui")]
private class Games.PreferencesPage: Gtk.Bin, Gtk.Buildable {
	public PreferencesSubpage subpage { get; protected set; }

	[GtkChild]
	private Gtk.Box box;

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		if (box != null)
			box.add (widget);
		else
			add (widget);
	}
}
