// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/keyboard-configurer.ui")]
private class Games.KeyboardConfigurer : Gtk.Box {
	private const GamepadInput[] KEYBOARD_GAMEPAD_INPUTS = {
		{ EventCode.EV_KEY, EventCode.BTN_A },
		{ EventCode.EV_KEY, EventCode.BTN_B },
		{ EventCode.EV_KEY, EventCode.BTN_X },
		{ EventCode.EV_KEY, EventCode.BTN_Y },
		{ EventCode.EV_KEY, EventCode.BTN_START },
		{ EventCode.EV_KEY, EventCode.BTN_SELECT },
		{ EventCode.EV_KEY, EventCode.BTN_THUMBL },
		{ EventCode.EV_KEY, EventCode.BTN_THUMBR },
		{ EventCode.EV_KEY, EventCode.BTN_TL },
		{ EventCode.EV_KEY, EventCode.BTN_TR },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_UP },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_LEFT },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_DOWN },
		{ EventCode.EV_KEY, EventCode.BTN_DPAD_RIGHT },
		{ EventCode.EV_KEY, EventCode.BTN_TL2 },
		{ EventCode.EV_KEY, EventCode.BTN_TR2 },
	};

	private const GamepadInputPath[] KEYBOARD_GAMEPAD_INPUT_PATHS = {
		{ { EventCode.EV_KEY, EventCode.BTN_A }, "a" },
		{ { EventCode.EV_KEY, EventCode.BTN_B }, "b" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_DOWN }, "dpdown" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_LEFT }, "dpleft" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_RIGHT }, "dpright" },
		{ { EventCode.EV_KEY, EventCode.BTN_DPAD_UP }, "dpup" },
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

	private const GamepadViewConfiguration KEYBOARD_GAMEPAD_VIEW_CONFIGURATION = {
		"resource:///org/gnome/Games/gamepads/standard-gamepad.svg", KEYBOARD_GAMEPAD_INPUT_PATHS
	};

	private enum State {
		TEST,
		CONFIGURE,
	}

	public signal void back ();

	private State _state;
	private State state {
		get { return _state; }
		set {
			_state = value;
			immersive_mode = (state == State.CONFIGURE);
			back_button.visible = (state == State.TEST);
			cancel_button.visible = (state == State.CONFIGURE);

			switch (value) {
			case State.TEST:
				reset_button.set_sensitive (!mapping_manager.is_default ());

				header_bar.title = _("Testing Keyboard");
				gamepad_view_stack.visible_child = tester;
				action_bar_stack.visible_child = tester_action_bar;

				tester.start ();
				mapper.stop ();
				mapper.finished.disconnect (on_mapper_finished);

				break;
			case State.CONFIGURE:
				header_bar.title = _("Configuring Keyboard");
				gamepad_view_stack.visible_child = mapper;
				action_bar_stack.visible_child = mapper_action_bar;

				tester.stop ();
				mapper.start ();
				mapper.finished.connect (on_mapper_finished);

				break;
			}
		}
	}

	[GtkChild (name = "header_bar")]
	private Gtk.HeaderBar _header_bar;
	public Gtk.HeaderBar header_bar {
		get { return _header_bar; }
		private set {}
	}

	public bool immersive_mode { get; private set; }

	[GtkChild]
	private Gtk.Stack gamepad_view_stack;
	[GtkChild]
	private Gtk.Stack action_bar_stack;
	[GtkChild]
	private Gtk.ActionBar tester_action_bar;
	[GtkChild]
	private Gtk.ActionBar mapper_action_bar;
	[GtkChild]
	private Gtk.Button reset_button;
	[GtkChild]
	private Gtk.Button back_button;
	[GtkChild]
	private Gtk.Button cancel_button;
	[GtkChild]
	private Gtk.Label info_message;

	private KeyboardMapper mapper;
	private KeyboardTester tester;
	private KeyboardMappingManager mapping_manager;

	private Binding info_message_binding;

	public KeyboardConfigurer () {
		mapper = new KeyboardMapper (KEYBOARD_GAMEPAD_VIEW_CONFIGURATION, KEYBOARD_GAMEPAD_INPUTS);
		gamepad_view_stack.add (mapper);
		tester = new KeyboardTester (KEYBOARD_GAMEPAD_VIEW_CONFIGURATION);
		gamepad_view_stack.add (tester);
		mapping_manager = new KeyboardMappingManager ();

		tester.mapping = mapping_manager.mapping;
		mapping_manager.changed.connect (() => {
			tester.mapping = mapping_manager.mapping;
		});

		info_message_binding = mapper.bind_property ("info-message", info_message, "label", BindingFlags.SYNC_CREATE);

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
					mapping_manager.delete_mapping ();
					reset_button.sensitive = false;

					break;
				default:
					break;
			}

			message_dialog.destroy ();
		});
		message_dialog.show ();
	}

	private void on_mapper_finished (Retro.KeyJoypadMapping mapping) {
		mapping_manager.save_mapping (mapping);

		state = State.TEST;
	}
}
