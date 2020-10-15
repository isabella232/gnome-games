// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-subpage-keyboard.ui")]
private class Games.PreferencesSubpageKeyboard : Gtk.Bin, PreferencesSubpage {
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

	private State _state;
	private State state {
		get { return _state; }
		set {
			_state = value;
			allow_back = (state == State.TEST);

			switch (value) {
			case State.TEST:
				reset_button.set_sensitive (!mapping_manager.is_default ());

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
	private Gtk.Button reset_button;

	private KeyboardMapper mapper;
	private KeyboardTester tester;
	private KeyboardMappingManager mapping_manager;

	construct {
		mapper = new KeyboardMapper (GamepadViewConfiguration.get_default (), KEYBOARD_GAMEPAD_INPUTS);
		tester = new KeyboardTester (GamepadViewConfiguration.get_default ());
		mapping_manager = new KeyboardMappingManager ();

		tester_box.add (tester);
		tester_box.reorder_child (tester, 1);
		mapper_box.add (mapper);
		mapper_box.reorder_child (mapper, 1);

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
		var dialog = new Gtk.MessageDialog (
			get_toplevel () as Gtk.Window,
			Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
			Gtk.MessageType.QUESTION,
			Gtk.ButtonsType.CANCEL,
			"%s",
			_("Factory reset mapping for this controller?")
		);

		dialog.format_secondary_text ("%s", _("Your mapping will be lost"));

		var button = dialog.add_button (C_("Confirm controller configuration factory reset", "_Reset"), Gtk.ResponseType.ACCEPT);
		button.get_style_context ().add_class ("destructive-action");

		dialog.response.connect ((response) => {
			switch (response) {
				case Gtk.ResponseType.ACCEPT:
					mapping_manager.delete_mapping ();
					reset_button.sensitive = false;

					break;
				default:
					break;
			}

			dialog.destroy ();
		});

		dialog.present ();
	}

	private void on_mapper_finished (Retro.KeyJoypadMapping mapping) {
		mapping_manager.save_mapping (mapping);

		state = State.TEST;
	}
}
