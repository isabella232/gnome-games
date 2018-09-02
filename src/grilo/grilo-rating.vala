// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloRating : Object, Rating {
	private GriloMedia media;
	private float rating;
	private bool resolving;

	public GriloRating (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public float get_rating () {
		if (resolving)
			return rating;

		resolving = true;
		media.try_resolve_media ();
		return rating;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		if (grl_media.length (Grl.MetadataKey.RATING) == 0)
			return;

		var media_rating = grl_media.get_rating ();
		load_media_rating (media_rating);
	}

	private void load_media_rating (float media_rating) {
		rating = media_rating;

		changed ();
	}
}
