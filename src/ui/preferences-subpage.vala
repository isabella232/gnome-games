// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.PreferencesSubpage: Gtk.Widget {
	public abstract Gtk.HeaderBar header_bar { get; }
	public abstract bool request_selection_mode { get; set; }
}
