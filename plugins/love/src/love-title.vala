// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.LoveTitle : Object, Title {
	private LovePackage package;
	private string? title;

	public LoveTitle (LovePackage package) {
		this.package = package;
	}

	public string get_title () throws Error {
		if (title != null)
			return title;

		title = package.get_config ("title");
		if (title != null)
			return title;

		title = package.get_config ("identity");
		if (title != null)
			return title;

		var uri = package.get_uri ();
		var file = uri.to_file ();

		try {
			var fileinfo = file.query_info (FileAttribute.STANDARD_DISPLAY_NAME,
			                                FileQueryInfoFlags.NONE,
			                                null);
			title = fileinfo.get_display_name ();
		} catch (Error e) {
			critical ("Couldn't retrieve filename: %s", e.message);
			title = file.get_basename ();
		}

		title = title.split (".")[0];
		title = title.split ("(")[0];
		title = title.strip ();

		return title;
	}
}
