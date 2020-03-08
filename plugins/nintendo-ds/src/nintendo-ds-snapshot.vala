// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.NintendoDsSnapshot : Snapshot {
	public NintendoDsLayout screen_layout { get; set; }
	public bool view_bottom_screen { get; set; }

	protected override void load_metadata (KeyFile keyfile) throws KeyFileError {
		base.load_metadata (keyfile);

		var layout_value = keyfile.get_string ("Nintendo DS", "Screen Layout");
		view_bottom_screen = keyfile.get_boolean ("Nintendo DS", "View Bottom Screen");

		screen_layout = NintendoDsLayout.from_value (layout_value);
	}

	protected override void save_metadata (KeyFile keyfile) {
		base.save_metadata (keyfile);

		keyfile.set_string ("Nintendo DS", "Screen Layout", screen_layout.get_value ());
		keyfile.set_boolean ("Nintendo DS", "View Bottom Screen", view_bottom_screen);
	}
}
