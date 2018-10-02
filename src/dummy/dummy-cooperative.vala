// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyCooperative : Object, Cooperative {
	public bool has_loaded { get; protected set; }

	public bool get_cooperative () {
		return false;
	}
}
