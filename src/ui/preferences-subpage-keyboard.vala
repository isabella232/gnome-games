// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-subpage-keyboard.ui")]
private class Games.PreferencesSubpageKeyboard : Gtk.Box, PreferencesSubpage {
	private const GamepadInput[] KEYBOARD_GAMEPAD_INPUTS = {
		{ EventCode.EV_KEY, EventCode.BTN_EAST },
		{ EventCode.EV_KEY, EventCode.BTN_SOUTH },
		{ EventCode.EV_KEY, EventCode.BTN_WEST },
		{ EventCode.EV_KEY, EventCode.BTN_NORTH },
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
			back_button.visible = (state == State.TEST);
			cancel_button.visible = (state == State.CONFIGURE);
			header_bar.show_close_button = (state == State.TEST);
			request_selection_mode = (state == State.CONFIGURE);
			allow_back = (state == State.TEST);

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
	private Hdy.HeaderBar _header_bar;
	public Hdy.HeaderBar header_bar {
		get { return _header_bar; }
	}

	public bool request_selection_mode { get; set; }
	public bool allow_back { get; set; }
	public string info_message { get; set; }

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

	private KeyboardMapper mapper;
	private KeyboardTester tester;
	private KeyboardMappingManager mapping_manager;

	construct {
		mapper = new KeyboardMapper (GamepadViewConfiguration.get_default (), KEYBOARD_GAMEPAD_INPUTS);
		gamepad_view_stack.add (mapper);
		tester = new KeyboardTester (GamepadViewConfiguration.get_default ());
		gamepad_view_stack.add (tester);
		mapping_manager = new KeyboardMappingManager ();

		tester.mapping = mapping_manager.mapping;
		mapping_manager.changed.connect (() => {
			tester.mapping = mapping_manager.mapping;
		});

		mapper.bind_property ("info-message", this, "info-message", BindingFlags.SYNC_CREATE);

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
