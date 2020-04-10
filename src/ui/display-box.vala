// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-box.ui")]
private class Games.DisplayBox : Gtk.Box {
	public signal void back ();
	public signal void snapshots_hidden ();
	public signal void restart ();

	public bool is_fullscreen { get; set; }
	public bool is_showing_snapshots { get; set; }

	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			if (runner != null)
				runner.snapshot_created.disconnect (flash_box.flash);

			stack.visible_child = display_overlay;

			_runner = value;
			remove_display ();
			header_bar.runner = runner;

			if (runner == null)
				return;

			var display = runner.get_display ();
			set_display (display);

			snapshots_list.runner = value;

			runner.snapshot_created.connect (flash_box.flash);
		}
	}

	public MediaSet? media_set {
		set { header_bar.media_set = value; }
	}

	public bool can_fullscreen { get; set; }
	public string game_title { get; set; }

	[GtkChild]
	private Gtk.Stack stack;
	[GtkChild]
	private ErrorDisplay error_display;
	[GtkChild]
	private Gtk.Overlay display_overlay;
	[GtkChild]
	private DisplayBin display_bin;
	[GtkChild]
	private FullscreenBox fullscreen_box;
	[GtkChild]
	private DisplayHeaderBar header_bar;
	[GtkChild]
	private FlashBox flash_box;
	[GtkChild]
	private SnapshotsList snapshots_list;

	public void display_running_game_failed (Game game, string error_message) {
		stack.visible_child = error_display;
		error_display.running_game_failed (game, error_message);
	}

	public void display_game_crashed (Game game, string error_message) {
		stack.visible_child = error_display;
		is_showing_snapshots = false;
		error_display.game_crashed (game, error_message);
	}

	[GtkCallback]
	public void update_fullscreen_box () {
		fullscreen_box.autohide = !header_bar.is_menu_open &&
		                          !is_showing_snapshots;
		fullscreen_box.overlay = is_fullscreen && !is_showing_snapshots;
	}

	[GtkCallback]
	private void on_header_bar_back () {
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

	public bool on_key_press_event (uint keyval, Gdk.ModifierType state) {
		if (!get_mapped ())
			return false;

		if (runner == null)
			return false;

		if (is_showing_snapshots)
			return snapshots_list.on_key_press_event (keyval, state);

		return runner.key_press_event (keyval, state);
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

	[GtkCallback]
	private void on_snapshots_list_size_allocate (Gtk.Allocation allocation) {
		display_bin.horizontal_offset = -allocation.width / 2;
	}

	[GtkCallback]
	private void on_snapshots_hidden () {
		snapshots_hidden ();
	}
}
