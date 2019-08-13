// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.NintendoDsSavestate : Savestate {
	public NintendoDsLayout screen_layout { get; set; }
	public bool view_bottom_screen { get; set; }

	public void load_extra_metadata () {
		var keyfile = get_metadata ();

		try {
			var layout_value = keyfile.get_string ("Nintendo DS", "Screen Layout");
			view_bottom_screen = keyfile.get_boolean ("Nintendo DS", "View Bottom Screen");

			screen_layout = NintendoDsLayout.from_value (layout_value);
		}
		catch (KeyFileError e) {
			critical ("Failed to get Nintendo DS metadata from metadata file for savestate at %s: %s", path, e.message);
			return;
		}
	}

	protected override void save_extra_metadata (KeyFile keyfile) {
		keyfile.set_string ("Nintendo DS", "Screen Layout", screen_layout.get_value ());
		keyfile.set_boolean ("Nintendo DS", "View Bottom Screen", view_bottom_screen);
	}
}
