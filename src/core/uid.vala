// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Uid : Object {
	private string uid;

	public Uid (string uid) {
		this.uid = uid;
	}

	public string get_uid () throws Error {
		return uid;
	}
}
