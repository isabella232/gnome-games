// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloReleaseDate : Object, ReleaseDate {
	private GriloMedia media;
	private DateTime release_date;
	private bool resolving;

	public GriloReleaseDate (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public DateTime get_release_date () {
		if (resolving)
			return release_date;

		if (release_date != null)
			return release_date;

		resolving = true;
		media.try_resolve_media ();

		return release_date;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		if (grl_media.length (Grl.MetadataKey.PUBLICATION_DATE) == 0)
			return;

		var release = grl_media.get_publication_date ();
		load_media_release_date (release);
	}

	private void load_media_release_date (DateTime release) {
		release_date = release;

		changed ();
	}
}
