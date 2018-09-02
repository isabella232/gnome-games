// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloPublisher : Object, Publisher {
	private GriloMedia media;
	private string publisher;
	private bool resolving;

	public GriloPublisher (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public string get_publisher () {
		if (resolving)
			return publisher;

		if (publisher != null)
			return publisher;

		resolving = true;
		media.try_resolve_media ();

		return publisher;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		var registry = Grl.Registry.get_default ();
		var metadata_key = registry.lookup_metadata_key ("publisher");

		if (grl_media.length (metadata_key) == 0)
			return;

		var publisher_string = grl_media.get_string (metadata_key);
		load_media_publisher (publisher_string);
	}

	private void load_media_publisher (string publisher_string) {
		publisher = publisher_string;

		changed ();
	}
}
