// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/screen-layout/screen-layout-item.ui")]
private class Games.ScreenLayoutItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Image icon;
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.Image checkmark;

	public ScreenLayout layout { get; construct; }

	public bool selected { get; set; default = false; }

	public ScreenLayoutItem (ScreenLayout layout) {
		Object (layout: layout);
	}

	construct {
		notify["selected"].connect (() => {
			checkmark.opacity = selected ? 1 : 0;
		});
	}

	public override void constructed () {
		icon.icon_name = layout.get_icon ();
		title.label = layout.get_title ();

		base.constructed ();
	}
}
