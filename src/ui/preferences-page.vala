// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PreferencesPage: Gtk.Bin, Gtk.Buildable {
	public PreferencesSubpage subpage { get; protected set; }

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		add (widget);
	}
}
