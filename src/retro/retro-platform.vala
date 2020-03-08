// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroPlatform : Object, Platform {
	private string name;
	private string id;
	private string[] mime_types;
	private string prefix;

	public RetroPlatform (string id, string name, string[] mime_types, string prefix) {
		this.id = id;
		this.name = name;
		this.mime_types = mime_types;
		this.prefix = prefix;
	}

	public string get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public string get_uid_prefix () {
		return prefix;
	}

	public string[] get_mime_types () {
		return mime_types;
	}

	public PreferencesPagePlatformsRow get_row () {
		return new PreferencesPagePlatformsRetroRow (this);
	}

	public virtual Type get_snapshot_type () {
		return typeof (Snapshot);
	}
}
