// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloRating : Object, Rating {
	private GriloMedia media;
	private float rating;
	private bool resolving;

	public bool has_loaded { get; protected set; }

	public GriloRating (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		rating = 0;
	}

	public float get_rating () {
		if (resolving || has_loaded)
			return rating;

		resolving = true;
		media.try_resolve_media_queued ();

		return rating;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		if (grl_media.length (Grl.MetadataKey.RATING) == 0)
			return;

		rating = grl_media.get_rating ();

		has_loaded = true;
	}
}
