// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyPlatform : Object, Platform {
	public string get_id () {
		return "Unknown";
	}

	public string get_name () {
		return _("Unknown");
	}

	public string get_uid_prefix () {
		return "unknown";
	}

	public PreferencesPagePlatformsRow get_row () {
		return new PreferencesPagePlatformsGenericRow (_("Unknown"));
	}

	public Type get_snapshot_type () {
		return typeof (Snapshot);
	}
}
