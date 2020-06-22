// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroFirmware : Object, Firmware {
	private string name;
	private bool is_mandatory;
	private string path;
	private string? md5;
	private string? sha512;

	public RetroFirmware (string name, Retro.CoreDescriptor core_descriptor) throws Error {
		this.name = name;

		if (core_descriptor.has_firmware_md5 (name))
			md5 = core_descriptor.get_firmware_md5 (name);
		if (core_descriptor.has_firmware_sha512 (name))
			sha512 = core_descriptor.get_firmware_sha512 (name);

		is_mandatory = core_descriptor.get_is_firmware_mandatory (name);
		path = core_descriptor.get_firmware_path (name);
	}

	public bool get_is_mandatory () {
		return is_mandatory;
	}

	public void check_is_valid (Platform platform) throws FirmwareError {
		var firmware_dir = File.new_for_path (platform.get_system_dir ());

		var firmware = firmware_dir.get_child (path);
		if (!firmware.query_exists ())
			throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file to run.", firmware.get_path ());

		if (md5 == null && sha512 == null)
			return;

		try {
			var stream = firmware.read ();

			stream.seek (0, SeekType.END);
			var size = (size_t) stream.tell ();
			stream.seek (0, SeekType.SET);
			var bytes = stream.read_bytes (size);

			if (md5 != null) {
				if (Checksum.compute_for_bytes (ChecksumType.MD5, bytes) != md5)
					throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file with a MD5 fingerprint of %s to run.", firmware.get_path (), md5);
			}

			if (sha512 != null) {
				if (Checksum.compute_for_bytes (ChecksumType.SHA512, bytes) != sha512)
					throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file with a SHA-512 fingerprint of %s to run.", firmware.get_path (), sha512);
			}
		} catch (Error e) {
			throw new FirmwareError.FIRMWARE_NOT_FOUND (e.message);
		}
	}
}
