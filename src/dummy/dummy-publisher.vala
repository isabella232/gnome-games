// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DummyPublisher : Object, Publisher {
	public bool has_loaded { get; protected set; }

	public string get_publisher () {
		return "";
	}
}
