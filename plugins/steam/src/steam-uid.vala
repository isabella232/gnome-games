// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamUid: Object, Uid {
	private string uid;
	private string app_id;

	public SteamUid (string app_id) {
		this.app_id = app_id;
	}

	public string get_uid () throws Error {
		if (uid != null)
			return uid;

		uid = @"steam-$app_id".down ();

		return uid;
	}
}
