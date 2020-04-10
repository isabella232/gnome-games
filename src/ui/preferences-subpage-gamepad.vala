// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-subpage-gamepad.ui")]
private class Games.PreferencesSubpageGamepad : Gtk.Bin, PreferencesSubpage {
	private const GamepadInput[] STANDARD_GAMEPAD_INPUTS = {
		{ EventCode.EV_KEY, EventCode.BTN_EAST },
		{ EventCode.EV_KEY, EventCode.BTN_SOUTH },
		{ EventCode.EV_KEY, EventCode.BTN_WEST },
		{ EventCode.EV_KEY, EventCode.BTN_NORTH },
		{ EventCode.EV_KEY, EventCode.BTN_START },
		{ EventCode.EV_KEY, EventCode.BTN_MODE },
		{ EventCode.EV_KEY, EventCode.BTN_SELECT },
		{ EventCode.EV_KEY, EventCode.BTN_THUMBL },
		{ EventCode.EV_KEY, EventCode.BTN_THUMBR },
		{ EventCode.EV_KEY, EventCode.BTN_TL },
		{ EventCode.EV_KEY, EventCode.BTN_TR },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_UP },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_LEFT },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_DOWN },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_RIGHT },
		{ EventCode.EV_ABS, EventCode.ABS_X },
		{ EventCode.EV_ABS, EventCode.ABS_Y },
		{ EventCode.EV_ABS, EventCode.ABS_RX },
		{ EventCode.EV_ABS, EventCode.ABS_RY },
		{ EventCode.EV_KEY, EventCode.BTN_TL2 },
		{ EventCode.EV_KEY, EventCode.BTN_TR2 },
	};

	private enum State {
		TEST,
		CONFIGURE,
	}

	public signal void back ();

	private State _state;
	private State state {
		set {
			_state = value;
			allow_back = (state == State.TEST);

			switch (value) {
			case State.TEST:
				reset_button.set_sensitive (device.has_user_mapping ());

				stack.visible_child = tester_box;

				tester.start ();
				mapper.stop ();
				mapper.finished.disconnect (on_mapper_finished);

				break;
			case State.CONFIGURE:
				stack.visible_child = mapper_box;

				tester.stop ();
				mapper.start ();
				mapper.finished.connect (on_mapper_finished);

				break;
			}
		}
		get { return _state; }
	}

	public bool allow_back { get; set; }
	public string info_message { get; set; }

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Gtk.Box tester_box;
	[GtkChild]
	private Gtk.Box mapper_box;
	[GtkChild]
	private Hdy.HeaderBar tester_header_bar;
	[GtkChild]
	private Hdy.HeaderBar mapper_header_bar;
	[GtkChild]
	private Gtk.Button reset_button;

	private GamepadMapper mapper;
	private GamepadTester tester;

	private Manette.Device _device;
	public Manette.Device device {
		get { return _device; }
		construct {
			_device = value;
			mapper = new GamepadMapper (value, GamepadViewConfiguration.get_default (), STANDARD_GAMEPAD_INPUTS);
			tester = new GamepadTester (value, GamepadViewConfiguration.get_default ());

			tester_box.add (tester);
			tester_box.reorder_child (tester, 1);
			mapper_box.add (mapper);
			mapper_box.reorder_child (mapper, 1);

			mapper.bind_property ("info-message", this, "info-message", BindingFlags.SYNC_CREATE);

			/* translators: testing a gamepad, %s is its name */
			tester_header_bar.title = _("Testing %s").printf (device.get_name ());
			/* translators: configuring a gamepad, %s is its name */
			mapper_header_bar.title = _("Configuring %s").printf (device.get_name ());
		}
	}

	public PreferencesSubpageGamepad (Manette.Device device) {
		Object (device: device);
	}

	construct {
		state = State.TEST;
	}

	[GtkCallback]
	private void on_reset_clicked () {
		reset_mapping ();
	}

	[GtkCallback]
	private void on_configure_clicked () {
		state = State.CONFIGURE;
	}

	[GtkCallback]
	private void on_skip_clicked () {
		mapper.skip ();
	}

	[GtkCallback]
	private void on_back_clicked () {
		back ();
	}

	[GtkCallback]
	private void on_cancel_clicked () {
		state = State.TEST;
	}

	private void reset_mapping () {
		var message_dialog = new ResetControllerMappingDialog ();
		message_dialog.transient_for = get_toplevel () as Gtk.Window;
		message_dialog.response.connect ((response) => {
			switch (response) {
				case Gtk.ResponseType.ACCEPT:
					device.remove_user_mapping ();
					reset_button.sensitive = false;

					break;
				default:
					break;
			}

			message_dialog.destroy ();
		});
		message_dialog.show ();
	}

	private void on_mapper_finished (string sdl_string) {
		device.save_user_mapping (sdl_string);
		state = State.TEST;
	}
}
