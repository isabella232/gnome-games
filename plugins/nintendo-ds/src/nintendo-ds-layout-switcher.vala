// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-ds/nintendo-ds-layout-switcher.ui")]
private class Games.NintendoDsLayoutSwitcher : Gtk.Box, HeaderBarWidget {
	[GtkChild]
	private Gtk.Revealer change_screen_revealer;
	[GtkChild]
	private Gtk.Image change_screen_image;
	[GtkChild]
	private Gtk.MenuButton layout_button;
	[GtkChild]
	private Gtk.Image layout_image;
	[GtkChild]
	private Gtk.Popover layout_popover;
	[GtkChild]
	private Gtk.ListBox list_box;

	private HashTable<NintendoDsLayout, NintendoDsLayoutItem> items;

	public NintendoDsRunner runner { get; construct; }

	private bool is_menu_open;
	public bool block_autohide {
		get { return is_menu_open; }
	}

	static construct {
		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.add_resource_path ("/org/gnome/Games/plugins/nintendo-ds/icons");
	}

	public override void constructed () {
		items = new HashTable<NintendoDsLayout, NintendoDsLayoutItem> (direct_hash, direct_equal);
		foreach (var layout in NintendoDsLayout.get_layouts ()) {
			var item = new NintendoDsLayoutItem (layout);

			items[layout] = item;
			list_box.add (item);
		}

		update_ui ();

		runner.notify["screen-layout"].connect (update_ui);
		runner.notify["view-bottom-screen"].connect (update_ui);

		base.constructed ();
	}

	public NintendoDsLayoutSwitcher (NintendoDsRunner runner) {
		Object (runner: runner);
	}

	[GtkCallback]
	private void on_menu_state_changed () {
		is_menu_open = layout_button.active;
		notify_property ("block-autohide");
	}

	[GtkCallback]
	private void update_ui () {
		var layout = runner.screen_layout;
		var view_bottom = runner.view_bottom_screen;

		layout_image.icon_name = layout.get_icon ();

		foreach (var item in items.get_values ())
			item.selected = item.layout == layout;

		var item = items[layout];
		list_box.select_row (item);

		change_screen_revealer.reveal_child = (layout == NintendoDsLayout.QUICK_SWITCH);
		change_screen_image.icon_name = view_bottom ?
		                                "view-top-screen-symbolic" :
		                                "view-bottom-screen-symbolic";
	}

	[GtkCallback]
	private void on_screen_changed (Gtk.Button button) {
		runner.view_bottom_screen = !runner.view_bottom_screen;
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow row) {
		var layout_item = row as NintendoDsLayoutItem;

		runner.screen_layout = layout_item.layout;

		layout_popover.popdown ();
	}
}
