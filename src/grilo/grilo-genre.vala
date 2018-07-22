// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloGenre : Object, Genre {
	private GriloMedia media;
	private Uid uid;
	private List<string> genre;
	private bool resolving;

	public GriloGenre (GriloMedia media, Uid uid) {
		this.media = media;
		this.uid = uid;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public unowned List<string> get_genre () {
		if (resolving)
			return genre;

		if (genre != null)
			return genre;

		resolving = true;
		media.try_resolve_media ();

		return genre;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		var genre_count = grl_media.length (Grl.MetadataKey.GENRE);

		if (genre_count == 0)
			return;

		var genre_list = new List<string> ();

		for(uint index = 0; index < genre_count; index++)
			genre_list.append(grl_media.get_genre_nth (index));

		load_media_genre (genre_list);
	}

	private void load_media_genre(List<string> genre_list) {
		genre = genre_list.copy();
		resolving = true;

		changed();
	}
}
