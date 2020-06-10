// This file is part of GNOME Games. License: GPL-3.0+.

errordomain Games.FirmwareError {
	FIRMWARE_NOT_FOUND,
}

public class Games.FirmwareManager : Object {
	public void is_all_firmware_valid (Core core, Platform platform) throws Error {
		var platforms_dir = Application.get_platforms_dir ();
		var platform_id = platform.get_id ();
		var firmware_dir = File.new_for_path (@"$platforms_dir/$platform_id/system");

		foreach (var firmware in core.get_all_firmware (platform)) {
			if (!core.get_is_firmware_mandatory (firmware))
				continue;

			var firmware_path = core.get_firmware_path (firmware);
			var firmware_file = firmware_dir.get_child (firmware_path);
			if (!firmware_file.query_exists ())
				throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file to run.", firmware_file.get_path ());

			check_firmware_is_valid (core, firmware, firmware_file);
		}
	}

	private void check_firmware_is_valid (Core core, string firmware, File firmware_file) throws Error {
		var has_md5 = core.has_firmware_md5 (firmware);
		var has_sha512 = core.has_firmware_sha512 (firmware);
		if (!has_md5 || !has_sha512)
			return;

		var stream = firmware_file.read ();

		stream.seek (0, SeekType.END);
		var size = (size_t) stream.tell ();
		stream.seek (0, SeekType.SET);
		var bytes = stream.read_bytes (size);

		if (has_md5) {
			var md5 = core.get_firmware_md5 (firmware);
			if (Checksum.compute_for_bytes (ChecksumType.MD5, bytes) != md5)
				throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file with a MD5 fingerprint of %s to run.", firmware_file.get_path (), md5);
		}

		if (has_sha512) {
			var sha512 = core.get_firmware_sha512 (firmware);
			if (Checksum.compute_for_bytes (ChecksumType.SHA512, bytes) != sha512)
				throw new FirmwareError.FIRMWARE_NOT_FOUND ("This game requires the %s firmware file with a SHA-512 fingerprint of %s to run.", firmware_file.get_path (), sha512);
		}
	}
}
