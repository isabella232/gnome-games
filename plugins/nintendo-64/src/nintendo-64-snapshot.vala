// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Nintendo64Snapshot : Snapshot {
	public Nintendo64Pak pak1 { get; set; }
	public Nintendo64Pak pak2 { get; set; }
	public Nintendo64Pak pak3 { get; set; }
	public Nintendo64Pak pak4 { get; set; }

	protected override void load_metadata (KeyFile keyfile) throws KeyFileError {
		base.load_metadata (keyfile);

		var value = keyfile.get_string ("Nintendo 64", "Pak 1");
		pak1 = Nintendo64Pak.from_value (value);

		value = keyfile.get_string ("Nintendo 64", "Pak 2");
		pak2 = Nintendo64Pak.from_value (value);

		value = keyfile.get_string ("Nintendo 64", "Pak 3");
		pak3 = Nintendo64Pak.from_value (value);

		value = keyfile.get_string ("Nintendo 64", "Pak 4");
		pak4 = Nintendo64Pak.from_value (value);
	}

	protected override void save_metadata (KeyFile keyfile) {
		base.save_metadata (keyfile);

		keyfile.set_string ("Nintendo 64", "Pak 1", pak1.get_value ());
		keyfile.set_string ("Nintendo 64", "Pak 2", pak2.get_value ());
		keyfile.set_string ("Nintendo 64", "Pak 3", pak3.get_value ());
		keyfile.set_string ("Nintendo 64", "Pak 4", pak4.get_value ());
	}
}
