// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DisplayBin : Gtk.Bin {
	private int _horizontal_offset;
	public int horizontal_offset {
		get { return _horizontal_offset; }
		set {
			if (horizontal_offset == value)
				return;

			_horizontal_offset = value;
			queue_allocate ();
		}
	}

	private int _vertical_offset;
	public int vertical_offset {
		get { return _vertical_offset; }
		set {
			if (vertical_offset == value)
				return;

			_vertical_offset = value;
			queue_allocate ();
		}
	}

	public override void size_allocate (int width, int height, int baseline) {
		var child = get_child ();
		if (child != null && child.visible) {
			Gsk.Transform transform = null;

			if (horizontal_offset != 0 && vertical_offset != 0) {
				Graphene.Point point = { horizontal_offset, vertical_offset };

				if (get_direction () == Gtk.TextDirection.RTL)
					point.x = -horizontal_offset;

				transform = transform.translate (point);
			}

			child.allocate (width, height, baseline, transform);
		}
	}
}
