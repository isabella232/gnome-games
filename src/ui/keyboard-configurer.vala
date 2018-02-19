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
		set {
			_state = value;
			immersive_mode = (state == State.CONFIGURE);

			switch (value) {
			case State.TEST:
				reset_button.set_sensitive (!mapping_manager.is_default ());

				back_button.show ();
				cancel_button.hide ();
				action_bar.show ();
				header_bar.title = _("Testing Keyboard");
				header_bar.get_style_context ().remove_class ("selection-mode");
				stack.set_visible_child_name ("keyboard_tester");

				tester.start ();
				mapper.stop ();
				mapper.finished.disconnect (on_mapper_finished);

				break;
			case State.CONFIGURE:
				back_button.hide ();
				cancel_button.show ();
				action_bar.hide ();
				header_bar.title = _("Configuring Keyboard");
				header_bar.get_style_context ().add_class ("selection-mode");
				stack.set_visible_child_name ("keyboard_mapper");

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
	private Gtk.Box keyboard_mapper_holder;
	[GtkChild]
	private Gtk.Box keyboard_tester_holder;
	[GtkChild]
	private Gtk.ActionBar action_bar;
	[GtkChild]
	private Gtk.Button reset_button;
	[GtkChild]
	private Gtk.Button back_button;
	[GtkChild]
	private Gtk.Button cancel_button;

	private KeyboardMapper mapper;
	private KeyboardTester tester;
	private KeyboardMappingManager mapping_manager;

	public KeyboardConfigurer () {
		mapper = new KeyboardMapper (KEYBOARD_GAMEPAD_VIEW_CONFIGURATION, KEYBOARD_GAMEPAD_INPUTS);
		keyboard_mapper_holder.pack_start (mapper);
		tester = new KeyboardTester (KEYBOARD_GAMEPAD_VIEW_CONFIGURATION);
		keyboard_tester_holder.pack_start (tester);
		mapping_manager = new KeyboardMappingManager ();

		tester.mapping = mapping_manager.mapping;
		mapping_manager.changed.connect (() => {
			tester.mapping = mapping_manager.mapping;
		});

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
		message_dialog.set_transient_for ((Gtk.Window) get_toplevel ());
		message_dialog.response.connect ((response) => {
			switch (response) {
				case Gtk.ResponseType.ACCEPT:
					mapping_manager.delete_mapping ();
					reset_button.set_sensitive (false);

					break;
				default:
					break;
			}

			message_dialog.destroy();
		});
		message_dialog.show ();
	}

	private void on_mapper_finished (Retro.KeyJoypadMapping mapping) {
		mapping_manager.save_mapping (mapping);

		state = State.TEST;
	}
}
