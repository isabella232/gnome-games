// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.AdaptiveState : Object {
	public bool is_showing_bottom_bar { get; set; }
	public bool is_folded { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }

	construct {
		is_showing_bottom_bar = false;
		is_folded = false;
		is_subview_open = false;
		subview_title = "";
	}
}
