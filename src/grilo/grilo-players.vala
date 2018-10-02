// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloPlayers : Object, Players {
	private GriloMedia media;
	private string players;
	private bool resolving;

	public bool has_loaded { get; protected set; }

	public GriloPlayers (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		players = "";
	}

	public string get_players () {
		if (resolving || has_loaded)
			return players;

		resolving = true;
		media.try_resolve_media ();

		return players;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		var registry = Grl.Registry.get_default ();
		var metadata_key = registry.lookup_metadata_key ("players");

		if (grl_media.length (metadata_key) == 0)
			return;

		var player = grl_media.get_string (metadata_key);

		if (int.parse (player) == 1)
			players = _("Single-player");
		else
			players = _("Multi-player");

		has_loaded = true;
	}
}
