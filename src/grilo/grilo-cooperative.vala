// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloCooperative : Object, Cooperative {
	private GriloMedia media;
	private Grl.KeyID GRL_METADATA_KEY_COOP;
	private Grl.Registry registry;
	private bool cooperative;
	private bool resolving;

	public GriloCooperative (GriloMedia media) {
		this.media = media;
		media.resolved.connect (on_media_resolved);
		resolving = false;
	}

	public bool get_cooperative () {
		if (resolving)
			return cooperative;

		resolving = true;
		media.try_resolve_media ();

		return cooperative;
	}

	private void on_media_resolved () {
		var grl_media = media.get_media ();

		if (grl_media == null)
			return;

		registry = Grl.Registry.get_default ();
		GRL_METADATA_KEY_COOP = registry.lookup_metadata_key ("coop");

		if (grl_media.length (GRL_METADATA_KEY_COOP) == 0)
			return;

		var coop = grl_media.get_boolean (GRL_METADATA_KEY_COOP);
		load_media_cooperative (coop);
	}

	private void load_media_cooperative (bool coop) {
		cooperative = coop;
		resolving = true;

		changed ();
	}
}
