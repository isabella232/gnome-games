// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloReleaseDate : Object, ReleaseDate {
	private GriloMedia media;
	private DateTime release_date;
	private bool resolving;
	private bool resolved;

	public GriloReleaseDate (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		release_date = null;
	}

	public DateTime get_release_date () {
		if (resolving || resolved)
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

		release_date = grl_media.get_publication_date ();

		resolved = true;

		changed ();
	}
}
