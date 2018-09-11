// This file is part of GNOME Games. License: GPL-3.0+.

private interface Games.PreferencesPage: Gtk.Widget {
	public abstract Gtk.HeaderBar header_bar { get; protected set; }
	public abstract PreferencesSubpage subpage { get; protected set; }
	public virtual void visible_page_changed () {}
}
