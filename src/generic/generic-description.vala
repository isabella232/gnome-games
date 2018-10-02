// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericDescription : Object, Description {
	private string description;

	public bool has_loaded { get; protected set; }

	construct {
		has_loaded = true;
	}

	public GenericDescription (string description) {
		this.description = description;
	}

	public string get_description () {
		return description;
	}
}
