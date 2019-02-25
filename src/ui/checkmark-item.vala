// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/checkmark-item.ui")]
private class Games.CheckmarkItem: Gtk.ListBoxRow {
	[GtkChild]
	private Gtk.Label title_label;
	[GtkChild]
	private Gtk.Image checkmark_image;

	public bool checkmark_visible { get; set; }
	private Binding checkmark_visible_binding;

	public string label {
		construct {
			title_label.label = value;
		}
	}

	public CheckmarkItem (string label) {
		Object (label: label);
	}

	construct {
		checkmark_visible_binding = bind_property ("checkmark-visible", checkmark_image, "visible",
		                                           BindingFlags.DEFAULT);
	}
}
