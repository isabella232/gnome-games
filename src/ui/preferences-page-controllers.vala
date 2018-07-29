// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-controllers.ui")]
private class Games.PreferencesPageControllers : PreferencesPage {
	[GtkChild]
	private Gtk.Label gamepads_label;
	[GtkChild]
	private Gtk.ListBox gamepads_list_box;
	[GtkChild]
	private Gtk.ListBox keyboard_list_box;

	private Manette.Monitor monitor;

	private ulong back_handler_id;

	construct {
		monitor = new Manette.Monitor ();
		monitor.device_connected.connect (rebuild_gamepad_list);
		monitor.device_disconnected.connect (rebuild_gamepad_list);
		build_gamepad_list ();
		build_keyboard_list ();
		title = _("Controllers");
	}

	private void rebuild_gamepad_list () {
		clear_gamepad_list ();
		build_gamepad_list ();
	}

	private void build_gamepad_list () {
		Manette.Device device = null;
		var i = 0;
		var iterator = monitor.iterate ();
		while (iterator.next (out device)) {
			i += 1;
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			box.add (new Gtk.Label (device.get_name ()));
			box.margin = 6;
			gamepads_list_box.add (box);
		}
		gamepads_label.visible = i > 0;
		gamepads_list_box.visible = i > 0;
	}

	private void clear_gamepad_list () {
		gamepads_list_box.foreach ((child) => child.destroy ());
	}

	[GtkCallback]
	private void gamepads_list_box_row_activated (Gtk.ListBoxRow row_item) {
		Manette.Device? device = null;
		Manette.Device other_device = null;
		var i = 0;
		var row_index = row_item.get_index ();

		var iterator = monitor.iterate ();
		while (iterator.next (out other_device)) {
			if (i++ == row_index)
				device = other_device;
		}

		if (device == null)
			return;

		var subpage_gamepad = new PreferencesSubpageGamepad (device);
		back_handler_id = subpage_gamepad.back.connect (on_back);
		subpage = subpage_gamepad;
	}

	private void build_keyboard_list () {
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.add (new Gtk.Label (_("Keyboard")));
		box.margin = 6;
		keyboard_list_box.add (box);
	}

	[GtkCallback]
	private void keyboard_list_box_row_activated (Gtk.ListBoxRow row_item) {
		var subpage_keyboard = new PreferencesSubpageKeyboard ();
		back_handler_id = subpage_keyboard.back.connect (on_back);
		subpage = subpage_keyboard;
	}

	private void on_back () {
		subpage.disconnect (back_handler_id);
		subpage = null;
	}
}
