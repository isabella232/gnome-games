// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.KeyboardMappingManager : Object {
	private const string MAPPING_FILE_NAME = "keyboard-mapping.txt";
	private const string GROUP_NAME = "KeyboardMapping";

	public signal void changed ();
	public Retro.KeyJoypadMapping mapping { get; private set; }

	private File mapping_file;
	private FileMonitor mapping_monitor;

	construct {
		var config_dir = Application.get_config_dir ();
		var path = Path.build_filename (config_dir, MAPPING_FILE_NAME);
		mapping_file = File.new_for_path (path);
		try {
			mapping_monitor = mapping_file.monitor (FileMonitorFlags.NONE, null);
			mapping_monitor.changed.connect (load_mapping);
		}
		catch (Error e) {
			critical (e.message);
		}

		load_mapping ();
	}

	private void load_mapping () {
		if (!mapping_file.query_exists ()) {
			debug ("User keyboard mapping file doesn't exist.");
			mapping = new Retro.KeyJoypadMapping.default ();
			changed ();

			return;
		}

		mapping = new Retro.KeyJoypadMapping ();
		var mapping_key_file = new KeyFile ();
		try {
			mapping_key_file.load_from_file (mapping_file.get_path (), KeyFileFlags.NONE);
		}
		catch (Error e) {
			critical (e.message);
			changed ();

			return;
		}

		var enumc = (EnumClass) typeof (Retro.JoypadId).class_ref ();

		foreach (var id in enumc.values) {
			var button = id.value_nick;
			try {
				var key = mapping_key_file.get_integer (GROUP_NAME, button);
				mapping.set_button_key ((Retro.JoypadId) id.value, (uint16) key);
			}
			catch (Error e) {
				critical (e.message);
			}
		}

		changed ();
	}

	public bool is_default () {
		return !mapping_file.query_exists ();
	}

	public void save_mapping (Retro.KeyJoypadMapping mapping) {
		var config_dir = Application.get_config_dir ();
		Application.try_make_dir (config_dir);

		var mapping_key_file = new KeyFile ();
		var enumc = (EnumClass) typeof (Retro.JoypadId).class_ref ();

		foreach (var id in enumc.values) {
			var button = id.value_nick;
			var key = mapping.get_button_key ((Retro.JoypadId) id.value);
			mapping_key_file.set_integer (GROUP_NAME, button, key);
		}

		try {
			mapping_key_file.save_to_file (mapping_file.get_path ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void delete_mapping () {
		if (!mapping_file.query_exists ())
			return;

		try {
			mapping_file.delete ();
		}
		catch (Error e) {
			critical (e.message);
		}
	}
}
