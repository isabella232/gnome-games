// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DesktopUid: Object, Uid {
	private string uid;
	private DesktopAppInfo app_info;

	public DesktopUid (DesktopAppInfo app_info) {
		this.app_info = app_info;
	}

	public string get_uid () throws Error {
		if (uid != null)
			return uid;

		var appid = app_info.get_id ();
		uid = @"desktop-$appid";

		return uid;
	}
}
