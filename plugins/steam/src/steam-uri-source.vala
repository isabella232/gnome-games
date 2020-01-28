// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.SteamUriSource : Object, UriSource {
	// From the home directory.
	private const string STEAM_DIR = "/.steam";
	// From the home directory.
	private const string REGISTRY_PATH = "/.steam/registry.vdf";

	private const string[] APPS_REGISTRY_PATH = { "Registry", "HKCU", "Software", "Valve", "Steam", "Apps" };

	private string uri_scheme;
	private SteamGameData game_data;

	public SteamUriSource (string base_dir, string uri_scheme, SteamGameData game_data) throws Error {
		this.uri_scheme = uri_scheme;
		this.game_data = game_data;

		var registry_path = base_dir + REGISTRY_PATH;
		var registry = new SteamRegistry (registry_path);

		// If `.steam` dir is a symlink, it could be pointing to another Steam
		// installation, so skip it altogether to avoid duplicating games
		if (FileUtils.test (base_dir + STEAM_DIR, FileTest.IS_SYMLINK))
			return;

		var children = registry.get_children (APPS_REGISTRY_PATH);
		foreach (var appid in children) {
			var path = APPS_REGISTRY_PATH;
			path += appid;

			string name = null;
			var installed = false;

			var app_children = registry.get_children (path);
			foreach (var child in app_children) {
				var lowercase = child.ascii_down ();
				var child_path = path;
				child_path += child;
				if (lowercase == "name") {
					name = registry.get_data (child_path).strip ();
				}
				else if (lowercase == "installed") {
					var installed_value = registry.get_data (child_path);
					installed = (installed_value == "1");
				}
			}

			// Only entries that contain names are actual games.
			// Others are DLC or tools like Proton.
			if (name == null || !installed)
				continue;

			game_data.add_game (appid, name);
		}
	}

	public UriIterator iterator () {
		return new SteamUriIterator (uri_scheme, game_data);
	}
}
