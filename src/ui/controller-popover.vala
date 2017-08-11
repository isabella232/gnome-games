// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/controller-popover.ui")]
private class Games.ControllerPopover : Gtk.Popover {
	[GtkChild]
	private Gtk.ListBox controllers_list_box;
	[GtkChild]
	private Gtk.Button reassign_button;

	private ControllerSet _controller_set;
	public ControllerSet controller_set {
		set {
			_controller_set = value;

			reset_controllers ();
			if (controller_set != null)
				controller_set.changed.connect (reset_controllers);
		}
		get { return _controller_set; }
	}

	private void reset_controllers () {
		reassign_button.sensitive = controller_set != null && controller_set.has_multiple_controllers;

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

	[GtkCallback]
	private void on_reassign_clicked () {
		popdown ();

		int width, height;
		var window = (Gtk.Window) get_toplevel ();
		window.get_size (out width, out height);

		var controller_reassigner = new ControllerReassigner ();
		controller_reassigner.set_transient_for (window);
		controller_reassigner.set_default_size (width / 2, height / 2);
		controller_reassigner.response.connect ((response) => {
			switch (response) {
			case Gtk.ResponseType.APPLY:
				controller_set.gamepads = controller_reassigner.controller_set.gamepads;
				controller_set.keyboard_port = controller_reassigner.controller_set.keyboard_port;
				controller_set.reset ();

				break;
			default:
				break;
			}

			controller_reassigner.destroy ();
		});
		controller_reassigner.show ();
	}
}
