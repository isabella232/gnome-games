// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.FlashBox : Gtk.Widget {
	private const int64 FLASH_DURATION = 500; //milliseconds

	static construct {
		set_css_name ("gamesflashbox");
	}

	construct {
		set_has_window (false);
		opacity = 0;
	}

	private int64 flash_start_time;
	private uint tick_callback_id;

	public void flash () {
		if (tick_callback_id == 0) {
			tick_callback_id = add_tick_callback (on_tick);
			visible = true;
		}

		flash_start_time = get_frame_clock ().get_frame_time () / 1000;
		opacity = 1;
	}

	private bool on_tick (Gtk.Widget widget, Gdk.FrameClock frame_clock) {
		var frame_time = frame_clock.get_frame_time () / 1000;
		var t = (double) (frame_time - flash_start_time) / FLASH_DURATION;

		opacity = 1 - ease_out_quad (t);

		if (t >= 1) {
			opacity = 0;
			visible = false;
			tick_callback_id = 0;

			return false;
		}

		return true;
	}

	private double ease_out_quad (double t) {
		return t * (2 - t);
	}

	public override void destroy () {
		if (tick_callback_id != 0)
			remove_tick_callback (tick_callback_id);
	}
}
