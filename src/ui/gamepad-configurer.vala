// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/gamepad-configurer.ui")]
private class Games.GamepadConfigurer : Gtk.Box {
	private const GamepadInput[] STANDARD_GAMEPAD_INPUTS = {
		{ EventCode.EV_KEY, EventCode.BTN_A },
		{ EventCode.EV_KEY, EventCode.BTN_B },
		{ EventCode.EV_KEY, EventCode.BTN_X },
		{ EventCode.EV_KEY, EventCode.BTN_Y },
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

	private const GamepadInputPath[] STANDARD_GAMEPAD_INPUT_PATHS = {
		{ { EventCode.EV_ABS, EventCode.ABS_X }, "leftx" },
		{ { EventCode.EV_ABS, EventCode.ABS_Y }, "lefty" },
		{ { EventCode.EV_ABS, EventCode.ABS_RX }, "rightx" },
		{ { EventCode.EV_ABS, EventCode.ABS_RY }, "righty" },
		{ { EventCode.EV_KEY, EventCode.BTN_A }, "a" },
		{ { EventCode.EV_KEY, EventCode.BTN_B }, "b" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_DOWN }, "dpdown" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_LEFT }, "dpleft" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_RIGHT }, "dpright" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_UP }, "dpup" },
		{ { EventCode.EV_KEY, EventCode.BTN_MODE }, "guide" },
		{ { EventCode.EV_KEY, EventCode.BTN_SELECT }, "back" },
		{ { EventCode.EV_KEY, EventCode.BTN_TL }, "leftshoulder" },
		{ { EventCode.EV_KEY, EventCode.BTN_TR }, "rightshoulder" },
		{ { EventCode.EV_KEY, EventCode.BTN_START }, "start" },
		{ { EventCode.EV_KEY, EventCode.BTN_THUMBL }, "leftstick" },
		{ { EventCode.EV_KEY, EventCode.BTN_THUMBR }, "rightstick" },
		{ { EventCode.EV_KEY, EventCode.BTN_TL2 }, "lefttrigger" },
		{ { EventCode.EV_KEY, EventCode.BTN_TR2 }, "righttrigger" },
		{ { EventCode.EV_KEY, EventCode.BTN_Y }, "x" },
		{ { EventCode.EV_KEY, EventCode.BTN_X }, "y" },
	};

	private const GamepadViewConfiguration STANDARD_GAMEPAD_VIEW_CONFIGURATION = {
		"resource:///org/gnome/Games/gamepads/standard-gamepad.svg", STANDARD_GAMEPAD_INPUT_PATHS
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
			immersive_mode = (state == State.CONFIGURE);
			back_button.visible = (state == State.TEST);
			cancel_button.visible = (state == State.CONFIGURE);
			action_bar.visible = (state == State.TEST);

			switch (value) {
			case State.TEST:
				reset_button.set_sensitive (device.has_user_mapping ());

				/* translators: testing a gamepad, %s is its name */
				header_bar.title = _("Testing %s").printf (device.get_name ());
				header_bar.get_style_context ().remove_class ("selection-mode");
				stack.visible_child = gamepad_tester_holder;

				tester.start ();
				mapper.stop ();
				mapper.finished.disconnect (on_mapper_finished);

				break;
			case State.CONFIGURE:
				/* translators: configuring a gamepad, %s is its name */
				header_bar.title = _("Configuring %s").printf (device.get_name ());
				header_bar.get_style_context ().add_class ("selection-mode");
				stack.visible_child = gamepad_mapper_holder;

				tester.stop ();
				mapper.start ();
				mapper.finished.connect (on_mapper_finished);

				break;
			}
		}
		get { return _state; }
	}

	[GtkChild (name = "header_bar")]
	private Gtk.HeaderBar _header_bar;
	public Gtk.HeaderBar header_bar {
		private set {}
		get { return _header_bar; }
	}

	public bool immersive_mode { private set; get; }

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private Gtk.Box gamepad_mapper_holder;
	[GtkChild]
	private Gtk.Box gamepad_tester_holder;
	[GtkChild]
	private Gtk.ActionBar action_bar;
	[GtkChild]
	private Gtk.Button reset_button;
	[GtkChild]
	private Gtk.Button back_button;
	[GtkChild]
	private Gtk.Button cancel_button;

	private Manette.Device device;
	private GamepadMapper mapper;
	private GamepadTester tester;

	public GamepadConfigurer (Manette.Device device) {
		this.device = device;
		mapper = new GamepadMapper (device, STANDARD_GAMEPAD_VIEW_CONFIGURATION, STANDARD_GAMEPAD_INPUTS);
		gamepad_mapper_holder.pack_start (mapper);
		tester = new GamepadTester (device, STANDARD_GAMEPAD_VIEW_CONFIGURATION);
		gamepad_tester_holder.pack_start (tester);

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
