// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GriloMediaQueue : Object {
	private Queue<GriloMedia> queue;
	private GriloMedia current_media;

	private static Once<GriloMediaQueue> instance;

	construct {
		queue = new Queue<GriloMedia> ();
	}

	private static GriloMediaQueue create_instance () {
		return new GriloMediaQueue ();
	}

	public static unowned GriloMediaQueue get_instance () {
		return instance.once (create_instance);
	}

	public void append (GriloMedia media) {
		queue.push_tail (media);

		if (current_media == null)
			load_next_media ();
	}

	private void load_next_media () {
		if (queue.is_empty ())
			return;

		current_media = queue.pop_head ();
		current_media.resolved.connect (load_next_media);
		current_media.try_resolve_media ();
	}
}
