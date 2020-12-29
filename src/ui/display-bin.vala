// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DisplayBin : Gtk.EventBox {
	private int _child_width;
	public int child_width {
		get { return _child_width; }
		set {
			if (child_width == value)
				return;

			_child_width = value;
			queue_allocate ();
		}
	}

	public override void get_preferred_width (out int minimum, out int natural) {
		var child = get_child ();

		minimum = 0;

		if (child != null)
			child.get_preferred_width (null, out natural);
		else
			natural = 0;
	}

	public override void size_allocate (Gtk.Allocation alloc) {
		base.size_allocate (alloc);

		int delta = alloc.width - child_width;
		var child = get_child ();
		if (child != null)
			child.size_allocate ({ delta / 2, 0, child_width, alloc.height });
	}
}
