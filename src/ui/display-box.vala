// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-box.ui")]
private class Games.DisplayBox : Gtk.Bin {
	public signal void back ();

	public bool is_fullscreen { get; set; }

	public DisplayHeaderBar header_bar {
		get { return fullscreen_header_bar; }
	}

	public SavestatesListState savestates_list_state {
		get { return savestates_list.state; }
		set {
			value.notify["is-revealed"].connect (on_savestates_list_revealed_changed);

			savestates_list.state = value;
			fullscreen_header_bar.savestates_list_state = value;
		}
	}

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			stack.visible_child = display_box;

			_runner = value;
			remove_display ();
			header_bar.runner = runner;

			if (runner == null)
				return;

			var display = runner.get_display ();
			set_display (display);

			savestates_list.runner = value;
		}
	}

	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private ErrorDisplay error_display;
	[GtkChild]
	private Gtk.Box display_box;
	[GtkChild]
	private Gtk.EventBox display_bin;
	[GtkChild]
	private DisplayHeaderBar fullscreen_header_bar;
	[GtkChild]
	private SavestatesList savestates_list;

	private Binding fullscreen_binding;
	private long timeout_id;

	construct {
		fullscreen_binding = bind_property ("is-fullscreen", fullscreen_box,
		                                    "is-fullscreen",
		                                    BindingFlags.BIDIRECTIONAL);
		timeout_id = -1;
	}

	public DisplayBox (SavestatesListState savestates_list_state) {
		Object (savestates_list_state: savestates_list_state);
	}

	public void display_running_game_failed (Game game, string error_message) {
		stack.visible_child = error_display;
		error_display.running_game_failed (game, error_message);
	}

	[GtkCallback]
	private void on_fullscreen_header_bar_back () {
		back ();
	}

	private void set_display (Gtk.Widget display) {
		remove_display ();
		display_bin.add (display);
		display.visible = true;
	}

	private void remove_display () {
		var child = display_bin.get_child ();
		if (child != null)
			display_bin.remove (child);
	}

	public bool on_key_press_event (Gdk.EventKey event) {
		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		return runner.key_press_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		return runner.gamepad_button_press_event (button);
	}

	public void on_savestates_list_revealed_changed () {
		fullscreen_box.autohide = !savestates_list.state.is_revealed;
	}
}
