// This file is part of GNOME Games. License: GPL-3.0+.

namespace Games {
	private const GamepadButtonPath[] STANDARD_GAMEPAD_BUTTON_PATHS = {
		{ { EventCode.EV_ABS, EventCode.ABS_X }, "leftx" },
		{ { EventCode.EV_ABS, EventCode.ABS_Y }, "lefty" },
		{ { EventCode.EV_ABS, EventCode.ABS_RX }, "rightx" },
		{ { EventCode.EV_ABS, EventCode.ABS_RY }, "righty" },
		{ { EventCode.EV_KEY, EventCode.BTN_EAST }, "east" },
		{ { EventCode.EV_KEY, EventCode.BTN_SOUTH }, "south" },
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
		{ { EventCode.EV_KEY, EventCode.BTN_NORTH }, "north" },
		{ { EventCode.EV_KEY, EventCode.BTN_WEST }, "west" },
	};

	private struct GamepadButtonPath {
		GamepadInput input;
		string path;
	}

	private struct GamepadAnalogPath {
		GamepadInput input_x;
		GamepadInput input_y;
		double offset_radius;
		string path;
	}

	private struct GamepadViewConfiguration {
		string svg_path;
		GamepadButtonPath[] button_paths;
		GamepadAnalogPath[] analog_paths;
		string[] background_paths;

		public static GamepadViewConfiguration get_default () {
			GamepadViewConfiguration conf = {};

			conf.svg_path = "/org/gnome/Games/gamepads/standard-gamepad.svg";
			conf.button_paths = STANDARD_GAMEPAD_BUTTON_PATHS;
			conf.analog_paths = {};
			conf.background_paths = {};

			return conf;
		}
	}
}
