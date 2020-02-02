// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Nintendo64Platform : RetroPlatform {
	public Nintendo64Platform (string id, string name, string[] mime_types, string prefix) {
		base (id, name, mime_types, prefix);
	}

	public override Type get_savestate_type () {
		return typeof (Nintendo64Savestate);
	}
}
