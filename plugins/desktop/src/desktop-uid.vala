// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DesktopUid: Object, Uid {
	private string uid;
	private string base_name;

	public DesktopUid (string base_name) {
		this.base_name = base_name;
	}

	public string get_uid () throws Error {
		if (uid != null)
			return uid;

		var hash = Checksum.compute_for_string (ChecksumType.SHA256, base_name);

		uid = @"desktop-$hash";

		return uid;
	}
}
