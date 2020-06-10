// This file is part of GNOME Games. License: GPL-3.0+

private class Games.RetroCore : Object, Core {
	private Retro.CoreDescriptor core_descriptor;

	public RetroCore (Retro.CoreDescriptor core_descriptor) {
		this.core_descriptor = core_descriptor;
	}

	public string[] get_all_firmware (Platform platform) throws Error {
		var platform_id = platform.get_id ();
		if (core_descriptor.has_firmwares (platform_id))
			return core_descriptor.get_firmwares (platform_id);
		else
			return {};
	}

	public bool has_firmware_md5 (string firmware) throws Error {
		return core_descriptor.has_firmware_md5 (firmware);
	}

	public bool has_firmware_sha512 (string firmware) throws Error {
		return core_descriptor.has_firmware_sha512 (firmware);
	}

	public string? get_firmware_md5 (string firmware) throws Error {
		return core_descriptor.get_firmware_md5 (firmware);
	}

	public string? get_firmware_sha512 (string firmware) throws Error {
		return core_descriptor.get_firmware_sha512 (firmware);
	}

	public bool get_is_firmware_mandatory (string firmware) throws Error {
		return core_descriptor.get_is_firmware_mandatory (firmware);
	}

	public string? get_firmware_path (string firmware) throws Error {
		return core_descriptor.get_firmware_path (firmware);
	}
}
