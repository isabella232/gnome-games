// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericCooperative : Object, Cooperative {
	private bool cooperative;

	public bool has_loaded { get; protected set; }

	construct {
		has_loaded = true;
	}

	public GenericCooperative (bool cooperative) {
		this.cooperative = cooperative;
	}

	public bool get_cooperative () {
		return cooperative;
	}
}
