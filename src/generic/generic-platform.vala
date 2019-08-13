// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlatform : Object, Platform {
	private string name;
	private string id;
	private string uid_prefix;

	public GenericPlatform (string id, string name, string uid_prefix) {
		this.id = id;
		this.name = name;
		this.uid_prefix = uid_prefix;
	}

	public string get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public string get_uid_prefix () {
		return uid_prefix;
	}

	public PreferencesPagePlatformsRow get_row () {
		return new PreferencesPagePlatformsGenericRow (name);
	}

	public Type get_savestate_type () {
		return typeof (Savestate);
	}
}
