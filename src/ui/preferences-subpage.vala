// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.PreferencesSubpage : Gtk.Widget {
	public signal void back ();

	public abstract bool allow_back { get; set; }
}
