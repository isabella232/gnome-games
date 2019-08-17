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
		icon.icon_name = layout.get_icon ();
		title.label = layout.get_title ();

		var subtitle_str = layout.get_subtitle ();
		if (subtitle_str != null) {
			subtitle.label = subtitle_str;
			subtitle.show ();
		}

		base.constructed ();
	}
}
