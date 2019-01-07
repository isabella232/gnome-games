// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroCoreSource : Object {
	private RetroPlatform platform;

	private Retro.CoreDescriptor core_descriptor;

	public RetroCoreSource (RetroPlatform platform) {
		this.platform = platform;
	}

	public Platform get_platform () {
		return platform;
	}

	public string get_module_path () throws Error {
		ensure_module_is_found ();

		var module_file = core_descriptor.get_module_file ();
		if (module_file == null) {
			var mime_types = platform.get_mime_types ();

			throw new RetroError.MODULE_NOT_FOUND (_("No module found for platform “%s” and MIME types [ “%s” ]."), platform.get_id (), string.joinv (_("”, “"), mime_types));
		}

		return module_file.get_path ();
	}

	private void ensure_module_is_found () throws Error {
		search_module ();

		var platform_id = platform.get_id ();

		if (core_descriptor == null) {
			var mime_types = platform.get_mime_types ();

			throw new RetroError.MODULE_NOT_FOUND (_("No module found for platform “%s” and MIME types [ “%s” ]."), platform_id, string.joinv (_("”, “"), mime_types));
		}

		if (core_descriptor.has_firmwares (platform_id))
			foreach (var firmware in core_descriptor_get_firmwares (core_descriptor, platform_id))
				check_firmware_is_valid (firmware);
	}

	private void search_module () throws Error {
		var core_manager = RetroCoreManager.get_instance ();

		var core_descriptors = core_manager.get_cores_for_platform (platform);

		if (core_descriptors.length > 0)
			core_descriptor = core_descriptors[0];
	}

	private void check_firmware_is_valid (string firmware) throws Error {
		if (!core_descriptor.get_is_firmware_mandatory (firmware))
			return;

		var platforms_dir = Application.get_platforms_dir ();
		var platform_id = platform.get_id ();
		var firmware_dir = File.new_for_path (@"$platforms_dir/$platform_id/system");
		var firmware_path = core_descriptor.get_firmware_path (firmware);
		var firmware_file = firmware_dir.get_child (firmware_path);
		if (!firmware_file.query_exists ())
			throw new RetroError.FIRMWARE_NOT_FOUND (_("This game requires the %s firmware file to run."), firmware_file.get_path ());

		var has_md5 = core_descriptor.has_firmware_md5 (firmware);
		var has_sha512 = core_descriptor.has_firmware_sha512 (firmware);
		if (!has_md5 || !has_sha512)
			return;

		var stream = firmware_file.read ();

		stream.seek (0, SeekType.END);
		var size = (size_t) stream.tell ();
		stream.seek (0, SeekType.SET);
		var bytes = stream.read_bytes (size);

		if (has_md5) {
			var md5 = core_descriptor.get_firmware_md5 (firmware);
			if (Checksum.compute_for_bytes (ChecksumType.MD5, bytes) != md5)
				throw new RetroError.FIRMWARE_NOT_FOUND (_("This game requires the %s firmware file with a MD5 fingerprint of %s to run."), firmware_file.get_path (), md5);
		}

		if (has_sha512) {
			var sha512 = core_descriptor.get_firmware_sha512 (firmware);
			if (Checksum.compute_for_bytes (ChecksumType.SHA512, bytes) != sha512)
				throw new RetroError.FIRMWARE_NOT_FOUND (_("This game requires the %s firmware file with a SHA-512 fingerprint of %s to run."), firmware_file.get_path (), sha512);
		}
	}

	// FIXME Workaround a bug in valac or vapigen preventing from using the
	// version from the retro-gtk VAPI.
	[CCode (cname="retro_core_descriptor_get_firmwares", array_length=true, array_length_cname="length", array_length_type="gsize")]
	private static extern string[] core_descriptor_get_firmwares (Retro.CoreDescriptor core_descriptor, string platform) throws Error;
}
