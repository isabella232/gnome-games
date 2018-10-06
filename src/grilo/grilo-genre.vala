// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloGenre : Object, Genre {
	private GriloMedia media;
	private string[] genre;
	private bool resolving;

	public bool has_loaded { get; protected set; }

	public GriloGenre (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		genre = {};
	}

	public unowned string[] get_genre () {
		if (resolving || has_loaded)
			return genre;

		resolving = true;
		media.try_resolve_media_queued ();

		return genre;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		var genre_count = grl_media.length (Grl.MetadataKey.GENRE);

		if (genre_count == 0)
			return;

		for (uint index = 0; index < genre_count; index++)
			genre += grl_media.get_genre_nth (index);

		has_loaded = true;
	}
}
