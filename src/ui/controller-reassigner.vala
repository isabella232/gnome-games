// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/controller-reassigner.ui")]
private class Games.ControllerReassigner : Gtk.Dialog {
	[GtkChild]
	private Gtk.ListBox controllers_list_box;

	public ControllerSet controller_set { private set; get; }

	private uint current_port;
	private GamepadMonitor gamepad_monitor;

	construct {
		use_header_bar = 1;

		controller_set = new ControllerSet ();
		controller_set.changed.connect (reset_controllers);
		current_port = 0;
		gamepad_monitor = GamepadMonitor.get_instance ();

		events |= Gdk.EventMask.KEY_RELEASE_MASK;
	}

	public ControllerReassigner () {
		key_release_event.connect (keyboard_event);
		gamepad_monitor.foreach_gamepad ((gamepad) => {
			gamepad.button_press_event.connect (gamepad_event);
		});
	}

	private void reset_controllers () {
		remove_controllers ();
		update_controllers ();
	}

	private void update_controllers () {
		if (controller_set == null)
			return;

		if (controller_set.has_gamepads) {
			controller_set.gamepads.foreach ((port, gamepad) => {
				add_controller (gamepad.name, port);
			});
		}
		if (controller_set.has_keyboard)
			add_controller (_("Keyboard"), controller_set.keyboard_port);
	}

	private void add_controller (string label, uint port) {
		var position = (int) port;
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (new Gtk.Label (position.to_string ()), false, false);
		box.pack_end (new Gtk.Label (label), false, false);
		box.spacing = 6;
		box.margin = 6;
		box.show_all ();
		controllers_list_box.insert (box, position);
	}

	private void remove_controllers () {
		controllers_list_box.foreach ((child) => child.destroy ());
	}

	private bool keyboard_event () {
		key_release_event.disconnect (keyboard_event);
		controller_set.keyboard_port = current_port++;

		return false;
	}

	private void gamepad_event (Gamepad gamepad, Event _) {
		gamepad.button_press_event.disconnect (gamepad_event);
		controller_set.add_gamepad (current_port++, gamepad);
	}
}
