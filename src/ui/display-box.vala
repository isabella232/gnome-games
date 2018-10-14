// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-box.ui")]
private class Games.DisplayBox : Gtk.Bin {
	public signal void back ();

	public bool is_fullscreen { get; set; }

	public DisplayHeaderBar header_bar {
		get { return fullscreen_header_bar; }
	}

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			stack.visible_child = display_bin;

			_runner = value;
			remove_display ();

			if (runner == null)
				return;

			var display = runner.get_display ();
			set_display (display);
		}
	}

	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private ErrorDisplay error_display;
	[GtkChild]
	private Gtk.EventBox display_bin;
	[GtkChild]
	private DisplayHeaderBar fullscreen_header_bar;
	private Binding fullscreen_binding;

	private long timeout_id;

	construct {
		fullscreen_binding = bind_property ("is-fullscreen", fullscreen_box,
		                                    "is-fullscreen",
		                                    BindingFlags.BIDIRECTIONAL);
		timeout_id = -1;
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
}
