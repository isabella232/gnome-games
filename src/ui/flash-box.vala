// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.FlashBox : Gtk.Widget {
	static construct {
		set_css_name ("gamesflashbox");
	}

	public override bool draw (Cairo.Context cr) {
		var width = get_allocated_width ();
		var height = get_allocated_height ();

		context.style.render_background (cr, 0.0, 0.0, width, height);
	}
}
