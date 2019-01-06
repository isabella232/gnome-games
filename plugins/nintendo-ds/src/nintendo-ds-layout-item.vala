// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-ds/ui/nintendo-ds-layout-item.ui")]
private class Games.NintendoDsLayoutItem : Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Image icon;
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.Label subtitle;

	private string layout;

	public NintendoDsLayoutItem (string layout, string title, string? subtitle, string icon) {
		this.layout = layout;

		this.icon.icon_name = icon;
		this.title.label = title;

		if (subtitle != null) {
			this.subtitle.label = subtitle;
			this.subtitle.show ();
		}
	}

	public string get_layout () {
		return layout;
	}
}
