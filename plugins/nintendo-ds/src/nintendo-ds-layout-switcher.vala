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
	private HashTable<string, NintendoDsLayoutItem> items;

	private string[] LAYOUTS = {
		"top/bottom",
		"left/right",
		"right/left",
		"quick switch",
	};

	static construct {
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.add_resource_path ("/org/gnome/Games/plugins/nintendo-ds/icons");
	}

	construct {
		items = new HashTable<string, NintendoDsLayoutItem> (str_hash, str_equal);
		foreach (string layout in LAYOUTS) {
			string icon = get_layout_icon (layout);
			string title = get_layout_title (layout);
			string subtitle = get_layout_subtitle (layout);

			var item = new NintendoDsLayoutItem (layout, title, subtitle, icon);
			items[layout] = item;

			list_box.add (item);
		}

		settings = new Settings ("org.gnome.Games.plugins.nintendo-ds");
		settings.changed.connect (update_ui);

		layout_popover.show.connect (update_ui);

		update_ui ();
	}

	private void update_ui () {
		var layout = settings.get_string ("screen-layout");
		var view_bottom = settings.get_boolean ("view-bottom-screen");

		layout_image.icon_name = get_layout_icon (layout);

		var item = items[layout];
		list_box.select_row (item);

		change_screen_revealer.reveal_child = (layout == "quick switch");
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

		var layout = layout_item.get_layout ();

		settings.set_string ("screen-layout", layout);

		layout_popover.popdown ();
	}

	private string get_layout_icon (string layout) {
		switch (layout) {
		case "top/bottom":
			return "screen-layout-top-bottom-symbolic";

		case "left/right":
			return "screen-layout-left-right-symbolic";

		case "right/left":
			return "screen-layout-right-left-symbolic";

		case "quick switch":
			return "screen-layout-quick-switch-symbolic";
		}

		return "video-display-symbolic";
	}

	private string get_layout_title (string layout) {
		switch (layout) {
		case "top/bottom":
			return _("Vertical");

		case "left/right":
		case "right/left":
			return _("Side by side");

		case "quick switch":
			return _("Single screen");
		}

		return _("Unknown");
	}

	private string? get_layout_subtitle (string layout) {
		switch (layout) {
		case "left/right":
			return _("Bottom to the right");

		case "right/left":
			return _("Bottom to the left");
		}

		return null;
	}
}
