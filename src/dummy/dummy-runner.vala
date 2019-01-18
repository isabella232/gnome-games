// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DummyRunner : Object, Runner {
	public bool can_fullscreen {
		get { return false; }
	}

	public bool can_quit_safely {
		get { return true; }
	}

	public bool can_resume {
		get { return false; }
	}

	public MediaSet? media_set {
		get { return null; }
	}

	public InputMode input_mode {
		get { return InputMode.NONE; }
		set { }
	}

	public bool check_is_valid (out string error_message) throws Error {
		error_message = "";

		return true;
	}

	public Gtk.Widget get_display () {
		return new DummyDisplay ();
	}

	public Gtk.Widget? get_extra_widget () {
		return null;
	}

	public void start () throws Error {
	}

	public void resume () throws Error {
	}

	public void pause () {
	}

	public void stop () {
	}

	public InputMode[] get_available_input_modes () {
		return { };
	}

	public bool key_press_event (Gdk.EventKey event) {
		return false;
	}

	public bool gamepad_button_press_event (uint16 button) {
		return false;
	}
}
