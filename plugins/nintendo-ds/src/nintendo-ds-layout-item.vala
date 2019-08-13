// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-ds/ui/nintendo-ds-layout-item.ui")]
private class Games.NintendoDsLayoutItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Image icon;
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.Label subtitle;

	public NintendoDsLayout layout { get; construct; }

	public NintendoDsLayoutItem (NintendoDsLayout layout) {
		Object (layout: layout);
	}

	public override void constructed () {
		this.icon.icon_name = layout.get_icon ();
		this.title.label = layout.get_title ();

		if (subtitle != null) {
			this.subtitle.label = layout.get_subtitle ();
			this.subtitle.show ();
		}

		base.constructed ();
	}
}
