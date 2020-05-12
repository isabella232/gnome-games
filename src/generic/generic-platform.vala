// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPlatform : Object, Platform {
	private string name;
	private string id;
	private string uid_prefix;

	public GenericPlatform (string id, string name, string uid_prefix) {
		this.id = id;
		this.name = name;
		this.uid_prefix = uid_prefix;
	}

	public string get_id () {
		return id;
	}

	public string get_name () {
		return name;
	}

	public string get_uid_prefix () {
		return uid_prefix;
	}

	public Gtk.ListBoxRow get_row () {
		var generic_row = new Hdy.ActionRow ();
		generic_row.title = name;
		return generic_row;
	}

	public Type get_snapshot_type () {
		return typeof (Snapshot);
	}
}
