// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericDeveloper : Object, Developer {
	private string developer;

	public bool has_loaded { get; protected set; }

	construct {
		has_loaded = true;
	}

	public GenericDeveloper (string developer) {
		this.developer = developer;
	}

	public string get_developer () {
		return developer;
	}
}
