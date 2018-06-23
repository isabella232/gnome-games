// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/shortcuts-window.ui")]
private class Games.ShortcutsWindow : Gtk.ShortcutsWindow {
	[GtkChild]
	private Gtk.ShortcutsShortcut collection_shortcut_left_stick;
	[GtkChild]
	private Gtk.ShortcutsShortcut collection_shortcut_dpad;
	[GtkChild]
	private Gtk.ShortcutsShortcut collection_shortcut_start;
	[GtkChild]
	private Gtk.ShortcutsShortcut collection_shortcut_south;
	[GtkChild]
	private Gtk.ShortcutsShortcut ingame_shortcut_alt_left;
	[GtkChild]
	private Gtk.ShortcutsShortcut ingame_shortcut_home;
	[GtkChild]
	private Gtk.ShortcutsShortcut ingame_shortcut_south;
	[GtkChild]
	private Gtk.ShortcutsShortcut ingame_shortcut_east;

	construct {
		update_direction ();

		collection_shortcut_left_stick.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/stick-symbolic.svg");
		collection_shortcut_dpad.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/dpad-symbolic.svg");
		collection_shortcut_start.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/button-start-symbolic.svg");
		collection_shortcut_south.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/button-south-symbolic.svg");
		ingame_shortcut_home.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/button-home-symbolic.svg");
		ingame_shortcut_south.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/button-south-symbolic.svg");
		ingame_shortcut_east.icon = icon_for_uri ("resource:///org/gnome/Games/gesture/button-east-symbolic.svg");
	}

	static GLib.Icon icon_for_uri (string uri) {
		var file = File.new_for_uri (uri);

		return new FileIcon (file);
	}

	[GtkCallback]
	private void update_direction () {
		ingame_shortcut_alt_left.accelerator = get_direction () == Gtk.TextDirection.LTR ? "<alt>Left" : "<alt>Right";
	}
}
