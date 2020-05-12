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

	public Gtk.ListBoxRow get_row () {
		var generic_row = new Hdy.ActionRow ();
		generic_row.title = _("Unknown");
		return generic_row;
	}

	public Type get_snapshot_type () {
		return typeof (Snapshot);
	}
}
