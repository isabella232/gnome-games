// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamUriIterator : Object, UriIterator {
	private string uri_scheme;
	private string[] appids;

	private int index;

	internal SteamUriIterator (string uri_scheme, SteamGameData game_data) {
		this.uri_scheme = uri_scheme;
		this.appids = game_data.get_appids ();
		index = -1;
	}

	public new Uri? get () {
		if (index >= appids.length)
			return null;

		var appid = appids[index];
		return new Uri (@"$uri_scheme://rungameid/$appid");
	}

	public bool next () {
		index++;

		return (index < appids.length);
	}
}
