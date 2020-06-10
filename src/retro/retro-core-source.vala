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

	public string get_core_id () throws Error {
		ensure_module_is_found ();

		return core_descriptor.get_id ();
	}

	public string get_module_path () throws Error {
		ensure_module_is_found ();

		var module_file = core_descriptor.get_module_file ();
		if (module_file == null) {
			var mime_types = platform.get_mime_types ();

			throw new RetroError.MODULE_NOT_FOUND ("No module found for platform “%s” and MIME types [ “%s” ].", platform.get_id (), string.joinv ("”, “", mime_types));
		}

		return module_file.get_path ();
	}

	private void ensure_module_is_found () throws Error {
		search_module ();

		var platform_id = platform.get_id ();
		var firmware_manager = new FirmwareManager ();
		var core = new RetroCore (core_descriptor);

		if (core_descriptor == null) {
			var mime_types = platform.get_mime_types ();

			throw new RetroError.MODULE_NOT_FOUND ("No module found for platform “%s” and MIME types [ “%s” ].", platform_id, string.joinv ("”, “", mime_types));
		}

		firmware_manager.is_all_firmware_valid (core, platform);
	}

	private void search_module () throws Error {
		var core_manager = RetroCoreManager.get_instance ();

		var core_descriptors = core_manager.get_cores_for_platform (platform);

		if (core_descriptors.length > 0)
			core_descriptor = core_descriptors[0];
	}
}
