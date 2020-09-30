// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-ds/ui/nintendo-ds-layout-item.ui")]
private class Games.NintendoDsLayoutItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Image icon;
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.Image checkmark;

	public NintendoDsLayout layout { get; construct; }

	public bool selected { get; set; default = false; }

	public NintendoDsLayoutItem (NintendoDsLayout layout) {
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
