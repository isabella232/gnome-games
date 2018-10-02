// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloPublisher : Object, Publisher {
	private GriloMedia media;
	private string publisher;
	private bool resolving;

	public bool has_loaded { get; protected set; }

	public GriloPublisher (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		publisher = "";
	}

	public string get_publisher () {
		if (resolving || has_loaded)
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

		publisher = grl_media.get_string (metadata_key);

		has_loaded = true;
	}
}
