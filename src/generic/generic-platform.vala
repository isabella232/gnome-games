// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlatform : Object, Platform {
	private string name;

	public GenericPlatform (string name) {
		this.name = name;
	}

	public string get_name () {
		return name;
	}
}
