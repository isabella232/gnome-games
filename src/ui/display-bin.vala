// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DisplayBin : Gtk.Bin {
	private int _horizontal_offset;
	public int horizontal_offset {
		get { return _horizontal_offset; }
		set {
			if (horizontal_offset == value)
				return;

			_horizontal_offset = value;
			queue_draw ();
		}
	}

	private int _vertical_offset;
	public int vertical_offset {
		get { return _vertical_offset; }
		set {
			if (vertical_offset == value)
				return;

			_vertical_offset = value;
			queue_draw ();
		}
	}

	public override bool draw (Cairo.Context cr) {
		if (get_direction () == Gtk.TextDirection.RTL)
			cr.translate (-horizontal_offset, vertical_offset);
		else
			cr.translate (horizontal_offset, vertical_offset);

		base.draw (cr);

		return true;
	}
}
