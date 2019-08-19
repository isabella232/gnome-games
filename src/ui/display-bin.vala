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

	public override void size_allocate (Gtk.Allocation allocation) {
		set_allocation (allocation);

		var child = get_child ();
		if (child != null && child.visible) {
			Gtk.Allocation child_allocation = {};

			if (get_direction () == Gtk.TextDirection.RTL)
				child_allocation.x = allocation.x - horizontal_offset;
			else
				child_allocation.x = allocation.x + horizontal_offset;
			child_allocation.y = allocation.y + vertical_offset;
			child_allocation.width = allocation.width;
			child_allocation.height = allocation.height;

			child.size_allocate (child_allocation);
		}
	}
}
