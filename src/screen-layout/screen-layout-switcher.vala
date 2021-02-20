// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/screen-layout/screen-layout-switcher.ui")]
public class Games.ScreenLayoutSwitcher : Gtk.Box, HeaderBarWidget {
	[GtkChild]
	private unowned Gtk.Revealer change_screen_revealer;
	[GtkChild]
	private unowned Gtk.Image change_screen_image;
	[GtkChild]
	private unowned Gtk.MenuButton layout_button;
	[GtkChild]
	private unowned Gtk.Image layout_image;
	[GtkChild]
	private unowned Gtk.Popover layout_popover;
	[GtkChild]
	private unowned Gtk.ListBox list_box;

	private HashTable<ScreenLayout, ScreenLayoutItem> items;

	public ScreenLayout screen_layout { get; set; }
	public bool view_bottom_screen { get; set; }

	private bool is_menu_open;
	public bool block_autohide {
		get { return is_menu_open; }
	}

	public override void constructed () {
		items = new HashTable<ScreenLayout, ScreenLayoutItem> (direct_hash, direct_equal);
		foreach (var layout in ScreenLayout.get_layouts ()) {
			var item = new ScreenLayoutItem (layout);

			items[layout] = item;
			list_box.add (item);
		}

		update_ui ();

		notify["screen-layout"].connect (update_ui);
		notify["view-bottom-screen"].connect (update_ui);

		base.constructed ();
	}

	[GtkCallback]
	private void on_menu_state_changed () {
		is_menu_open = layout_button.active;
		notify_property ("block-autohide");
	}

	[GtkCallback]
	private void update_ui () {
		layout_image.icon_name = screen_layout.get_icon ();

		foreach (var item in items.get_values ())
			item.selected = item.layout == screen_layout;

		var item = items[screen_layout];
		list_box.select_row (item);

		change_screen_revealer.reveal_child = (screen_layout == ScreenLayout.QUICK_SWITCH);
		change_screen_image.icon_name = view_bottom_screen ?
		                                "view-top-screen-symbolic" :
		                                "view-bottom-screen-symbolic";
	}

	[GtkCallback]
	private void on_screen_changed () {
		view_bottom_screen = !view_bottom_screen;
	}

	[GtkCallback]
	private void on_row_activated (Gtk.ListBoxRow row) {
		var layout_item = row as ScreenLayoutItem;

		screen_layout = layout_item.layout;

		layout_popover.popdown ();
	}
}
