// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlatform : Object, Platform {
	private string name;
	private string id;

	public GenericPlatform (string id, string name) {
		this.id = id;
		this.name = name;
	}

	public string get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public PreferencesPagePlatformsRow get_row () {
		return new PreferencesPagePlatformsGenericRow (name);
	}
}
