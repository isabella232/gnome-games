// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.NintendoDsPlatform : RetroPlatform {
	public NintendoDsPlatform (string id, string name, string[] mime_types, string prefix) {
		base (id, name, mime_types, prefix);
	}

	public override Type get_snapshot_type () {
		return typeof (NintendoDsSnapshot);
	}
}
