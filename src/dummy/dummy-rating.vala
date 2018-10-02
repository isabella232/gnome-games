// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyRating : Object, Rating {
	public bool has_loaded { get; protected set; }

	public float get_rating () {
		return 0;
	}
}
