// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlatform : Object, Platform {
	private string platform;

	public GenericPlatform (string platform) {
		this.platform = platform;
	}

	public string get_name () {
		return platform;
	}
}
