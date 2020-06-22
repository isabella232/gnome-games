// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.FirmwareManager : Object {
	public void is_all_firmware_valid (Core core, Platform platform) throws Error {
		foreach (var firmware in core.get_all_firmware (platform)) {
			if (!firmware.get_is_mandatory ())
				continue;

			firmware.check_is_valid (platform);
		}
	}
}
