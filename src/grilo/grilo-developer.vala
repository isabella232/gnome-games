// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloDeveloper : Object, Developer {
	private GriloMedia media;
	private string developer;
	private bool resolving;

	public GriloDeveloper (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public string get_developer () {
		if (resolving)
			return developer;

		if (developer != null)
			return developer;

		resolving = true;
		media.try_resolve_media ();

		return developer;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		var registry = Grl.Registry.get_default ();
		var grl_metadata_key_developer = registry.lookup_metadata_key ("developer");

		if (grl_media.length (grl_metadata_key_developer) == 0)
			return;

		var developer_string = grl_media.get_string (grl_metadata_key_developer);
		load_media_developer (developer_string);
	}

	private void load_media_developer (string developer_string) {
		developer = developer_string;
		resolving = true;

		changed();
	}
}
