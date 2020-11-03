// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GdiTrackNode : Object {
	public File file { construct; get; }
	public int track_number { construct; get; }

	public GdiTrackNode (File file, int track_number) {
		Object (file: file, track_number: track_number);
	}
}
