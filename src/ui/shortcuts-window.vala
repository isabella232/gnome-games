// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/shortcuts-window.ui")]
private class Games.ShortcutsWindow : Gtk.ShortcutsWindow {
	[GtkChild]
	private Gtk.ShortcutsShortcut ingame_shortcut_alt_left;

	construct {
		update_direction ();
	}

	[GtkCallback]
	private void update_direction () {
		ingame_shortcut_alt_left.accelerator = get_direction () == Gtk.TextDirection.LTR ? "<alt>Left" : "<alt>Right";
	}
}
