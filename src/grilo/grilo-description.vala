// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloDescription : Object, Description {
	private GriloMedia media;
	private string description;
	private bool resolving;

	public GriloDescription (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public string get_description () {
		if (resolving)
			return description;

		if (description != null)
			return description;

		resolving = true;
		media.try_resolve_media ();

		return description;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		if (grl_media.length (Grl.MetadataKey.DESCRIPTION) == 0)
			return;

		var description_string = grl_media.get_description ();
		load_media_description (description_string);
	}

	private void load_media_description (string description_string) {
		description = description_string;

		changed ();
	}
}
