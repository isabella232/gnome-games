// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.TitlebarBox : Gtk.Container, Gtk.Buildable {
	private Gtk.Widget _titlebar;
	public Gtk.Widget titlebar {
		get { return _titlebar; }
		set {
			if (titlebar == value)
				return;

			if (titlebar != null)
				titlebar.unparent ();

			_titlebar = value;

			if (titlebar != null)
				titlebar.set_parent (this);
		}
	}

	private Gtk.Widget _content;
	public Gtk.Widget content {
		get { return _content; }
		set {
			if (content == value)
				return;

			if (content != null)
				content.unparent ();

			_content = value;

			if (content != null)
				content.set_parent (this);
		}
	}

	private bool _overlay;
	public bool overlay {
		get { return _overlay; }
		set {
			if (overlay == value)
				return;

			_overlay = value;

			animate_overlay ();
		}
	}

	private bool _reveal_titlebar;
	public bool reveal_titlebar {
		get { return _reveal_titlebar; }
		set {
			if (reveal_titlebar == value)
				return;

			_reveal_titlebar = value;

			animate_reveal ();
		}
	}

	public int overlay_duration { get; set; default = 250; }
	public int reveal_duration { get; set; default = 250; }

	private int64 overlay_start_time;
	private uint overlay_tick_cb_id;
	private double overlay_progress;


	private int64 reveal_start_time;
	private uint reveal_tick_cb_id;
	private double reveal_progress;

	construct {
		set_has_window (false);

		reveal_titlebar = true;
		reveal_progress = 1;
	}

	private void animate_overlay () {
		if (!Hdy.get_enable_animations (this) || !get_mapped ()) {
			overlay_progress = overlay ? 1 : 0;
			queue_resize ();
			return;
		}

		if (overlay_tick_cb_id != 0) {
			remove_tick_callback (overlay_tick_cb_id);
			overlay_tick_cb_id = 0;
		}

		overlay_start_time = get_frame_clock ().get_frame_time () / 1000;
		overlay_progress = overlay ? 0 : 1;
		overlay_tick_cb_id = add_tick_callback (overlay_tick_cb);
	}

	private bool overlay_tick_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
		var frame_time = frame_clock.get_frame_time () / 1000;
		var t = (double) (frame_time - overlay_start_time) / overlay_duration;

		if (t >= 1) {
			overlay_progress = overlay ? 1 : 0;
			overlay_tick_cb_id = 0;

			queue_resize ();

			return false;
		}

		overlay_progress = ease_out_cubic (t);

		if (!overlay)
			overlay_progress = 1 - overlay_progress;

		queue_resize ();

		return true;
	}

	private void animate_reveal () {
		if (!Hdy.get_enable_animations (this) || !get_mapped ()) {
			reveal_progress = reveal_titlebar ? 1 : 0;
			queue_resize ();
			return;
		}

		if (reveal_tick_cb_id != 0) {
			remove_tick_callback (reveal_tick_cb_id);
			reveal_tick_cb_id = 0;
		}

		reveal_start_time = get_frame_clock ().get_frame_time () / 1000;
		reveal_progress = reveal_titlebar ? 0 : 1;
		reveal_tick_cb_id = add_tick_callback (reveal_tick_cb);
	}

	private bool reveal_tick_cb (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
		var frame_time = frame_clock.get_frame_time () / 1000;
		var t = (double) (frame_time - reveal_start_time) / reveal_duration;

		if (t >= 1) {
			reveal_progress = reveal_titlebar ? 1 : 0;
			reveal_tick_cb_id = 0;

			queue_resize ();

			return false;
		}

		reveal_progress = ease_out_cubic (t);

		if (!reveal_titlebar)
			reveal_progress = 1 - reveal_progress;

		queue_resize ();

		return true;
	}

	private double ease_out_cubic (double t) {
		double p = t - 1;
		return p * p * p + 1;
	}

	protected override void get_preferred_width (out int min, out int nat) {
		int content_min, content_nat, titlebar_min, titlebar_nat;

		if (titlebar != null)
			titlebar.get_preferred_width (out titlebar_min, out titlebar_nat);
		else
			titlebar_min = titlebar_nat = 0;

		if (content != null)
			content.get_preferred_width (out content_min, out content_nat);
		else
			content_min = content_nat = 0;

		min = int.max (content_min, titlebar_min);
		nat = int.max (content_nat, titlebar_nat);
	}

	private int adjust_for_overlay (int height) {
		var progress = double.min (1 - overlay_progress, reveal_progress);

		return (int) Math.round (height * progress);
	}

	protected override void get_preferred_height (out int min, out int nat) {
		int content_min, content_nat, titlebar_min, titlebar_nat;

		if (titlebar != null)
			titlebar.get_preferred_height (out titlebar_min, out titlebar_nat);
		else
			titlebar_min = titlebar_nat = 0;

		if (content != null)
			content.get_preferred_height (out content_min, out content_nat);
		else
			content_min = content_nat = 0;

		min = int.max (content_min + adjust_for_overlay (titlebar_min), titlebar_min);
		nat = int.max (content_nat + adjust_for_overlay (titlebar_nat), titlebar_nat);
	}

	protected override void size_allocate (Gtk.Allocation alloc) {
		int titlebar_height = 0;

		if (titlebar != null) {
			int min, nat;
			titlebar.get_preferred_height (out min, out nat);

			titlebar_height = int.max (min, nat);

			titlebar.size_allocate ({
				alloc.x,
				alloc.y - (int) Math.round (titlebar_height * (1 - reveal_progress)),
				alloc.width,
				titlebar_height
			});
		}

		titlebar_height = adjust_for_overlay (titlebar_height);

		if (content != null)
			content.size_allocate ({
				alloc.x,
				alloc.y + titlebar_height,
				alloc.width,
				alloc.height - titlebar_height
			});

		base.size_allocate (alloc);
	}

	protected override void add (Gtk.Widget widget) {
		return_if_fail (content == null);

		if (content == null)
			content = widget;
	}

	protected override void remove (Gtk.Widget widget) {
		return_if_fail (widget == titlebar || widget == content);

		if (widget == titlebar)
			titlebar = null;
		else
			content = null;
	}

	protected override void forall_internal (bool include_internals, Gtk.Callback callback) {
		if (content != null)
			callback (content);

		if (titlebar != null)
			callback (titlebar);
	}

	public void add_child (Gtk.Builder builder, Object child, string? type) {
		var widget = child as Gtk.Widget;

		if (type == "titlebar")
			titlebar = widget;
		else
			content = content;
	}
}
