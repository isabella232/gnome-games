// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.PreferencesPage: Gtk.Widget {
	public abstract PreferencesSubpage subpage { get; protected set; }
}
