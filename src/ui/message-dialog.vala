// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.MessageDialog : Gtk.MessageDialog {
	public bool gamepad_button_press_event (Manette.Event event) {
		if (!visible)
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_A:
			response (Gtk.ResponseType.ACCEPT);

			return true;
		case EventCode.BTN_B:
			response (Gtk.ResponseType.CANCEL);

			return true;
		default:
			return false;
		}
	}
}
