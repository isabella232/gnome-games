// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyDeveloper : Object, Developer {
	public bool has_loaded { get; protected set; }

	public string get_developer () {
		return "";
	}
}
