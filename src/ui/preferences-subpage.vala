// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.PreferencesSubpage : Gtk.Widget {
	public abstract Hdy.HeaderBar header_bar { get; }
	public abstract bool request_selection_mode { get; set; }
	public abstract bool allow_back { get; set; }
}
