// This file is part of GNOME Games. License: GPL-3.0+.

namespace Games {
	private struct GamepadInputPath {
		GamepadInput input;
		string path;
	}

	private struct GamepadViewConfiguration {
		string svg_path;
		GamepadInputPath[] input_paths;
	}
}
