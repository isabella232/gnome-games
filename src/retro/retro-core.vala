// This file is part of GNOME Games. License: GPL-3.0+

private class Games.RetroCore : Object, Core {
	private Retro.CoreDescriptor core_descriptor;

	public RetroCore (Retro.CoreDescriptor core_descriptor) {
		this.core_descriptor = core_descriptor;
	}

	public Firmware[] get_all_firmware (Platform platform) throws Error {
		var platform_id = platform.get_id ();
		Firmware[] firmware_list = {};
		if (core_descriptor.has_firmwares (platform_id))
			foreach (var firmware in core_descriptor.get_firmwares (platform_id))
				firmware_list += new RetroFirmware (firmware, core_descriptor);

		return firmware_list;
	}
}
