// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-ds/ui/nintendo-ds-layout-switcher.ui")]
private class Games.NintendoDsLayoutSwitcher : Gtk.Box {
	[GtkChild]
	private Gtk.Revealer change_screen_revealer;
	[GtkChild]
	private Gtk.Image change_screen_image;
	[GtkChild]
	private Gtk.Image layout_image;
	[GtkChild]
	private Gtk.Popover layout_popover;
	[GtkChild]
	private Gtk.ListBox list_box;

	private Settings settings;
	private HashTable<NintendoDsLayout, NintendoDsLayoutItem> items;

	static construct {
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.add_resource_path ("/org/gnome/Games/plugins/nintendo-ds/icons");
	}

	construct {
		items = new HashTable<NintendoDsLayout, NintendoDsLayoutItem> (direct_hash, direct_equal);
		foreach (var layout in NintendoDsLayout.get_layouts ()) {
			var item = new NintendoDsLayoutItem (layout);

			items[layout] = item;
			list_box.add (item);
		}

		settings = new Settings ("org.gnome.Games.plugins.nintendo-ds");
		settings.changed.connect (update_ui);

		layout_popover.show.connect (update_ui);

		update_ui ();
	}

	private void update_ui () {
		var layout_value = settings.get_string ("screen-layout");
		var view_bottom = settings.get_boolean ("view-bottom-screen");

		var layout = NintendoDsLayout.from_value (layout_value);
		layout_image.icon_name = layout.get_icon ();

		var item = items[layout];
		list_box.select_row (item);

		change_screen_revealer.reveal_child = (layout == NintendoDsLayout.QUICK_SWITCH);
		change_screen_image.icon_name = view_bottom ? "view-top-screen-symbolic" : "view-bottom-screen-symbolic-symbolic";
	}

	[GtkCallback]
	private void on_screen_changed (Gtk.Button button) {
		var view_bottom = settings.get_boolean ("view-bottom-screen");

		settings.set_boolean ("view-bottom-screen", !view_bottom);
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow row) {
		var layout_item = row as NintendoDsLayoutItem;

		var layout = layout_item.layout;

		settings.set_string ("screen-layout", layout.get_value ());

		layout_popover.popdown ();
	}
}
