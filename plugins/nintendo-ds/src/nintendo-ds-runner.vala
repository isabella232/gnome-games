// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.NintendoDsRunner : Object, Runner {
	private RetroRunner runner;
	private Settings settings;
	private ulong settings_changed_id;

	private const string SCREENS_LAYOUT_OPTION = "desmume_screens_layout";

	public NintendoDsRunner (RetroRunner runner) {
		this.runner = runner;

		runner.game_init.connect (on_init);
		runner.game_deinit.connect (on_deinit);
	}

	private bool core_supports_layouts () {
		var core = runner.get_core ();

		return core != null && core.has_option (SCREENS_LAYOUT_OPTION);
	}

	private void on_init () {
		settings = new Settings ("org.gnome.Games.plugins.nintendo-ds");
		settings_changed_id = settings.changed.connect (on_changed);

		var core = runner.get_core ();

		core.options_set.connect (update_screen_layout);
	}

	private void on_deinit () {
		if (settings_changed_id > 0) {
			settings.disconnect (settings_changed_id);
			settings_changed_id = 0;

			settings = null;
		}
	}

	private void on_changed (string key) {
		if (key == "screen-layout" || key == "view-bottom-screen")
			update_screen_layout ();
	}

	private void update_screen_layout () {
		if (!core_supports_layouts ())
			return;

		var core = runner.get_core ();

		var option = core.get_option (SCREENS_LAYOUT_OPTION);

		var setting_value = settings.get_string ("screen-layout");

		var option_value = setting_value;
		if (setting_value == "quick switch") {
			var bottom = settings.get_boolean ("view-bottom-screen");

			option_value = bottom ? "bottom only" : "top only";
		}

		try {
			option.set_value (option_value);
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public bool can_fullscreen {
		get { return runner.can_fullscreen; }
	}

	public bool can_quit_safely {
		get { return runner.can_quit_safely; }
	}

	public bool can_resume {
		get { return runner.can_resume; }
	}

	public MediaSet? media_set {
		get { return runner.media_set; }
	}

	public InputMode input_mode {
		get { return runner.input_mode; }
		set { runner.input_mode = value; }
	}

	public bool check_is_valid (out string error_message) throws Error {
		return runner.check_is_valid (out error_message);
	}

	public Gtk.Widget get_display () {
		return runner.get_display ();
	}

	public Gtk.Widget? get_extra_widget () {
		if (!core_supports_layouts ())
			return null;

		return new NintendoDsLayoutSwitcher ();
	}

	public void start () throws Error {
		runner.start ();
	}

	public void resume () throws Error {
		runner.resume ();
	}

	public void pause () {
		runner.pause ();
	}

	public void stop () {
		runner.stop ();
	}

	public InputMode[] get_available_input_modes () {
		return runner.get_available_input_modes ();
	}

	public bool key_press_event (Gdk.EventKey event) {
		var layout = settings.get_string ("screen-layout");

		if (layout != "quick switch")
			return false;

		var view_bottom = settings.get_boolean ("view-bottom-screen");
		var switch_keyval = view_bottom ? Gdk.Key.Page_Up : Gdk.Key.Page_Down;
		if (event.keyval == switch_keyval)
			return swap_screens ();

		return false;
	}

	public bool gamepad_button_press_event (uint16 button) {
		if (button == EventCode.BTN_THUMBR)
			return swap_screens ();

		return false;
	}

	private bool swap_screens () {
		var layout = settings.get_string ("screen-layout");

		if (layout != "quick switch")
			return false;

		var view_bottom = settings.get_boolean ("view-bottom-screen");
		settings.set_boolean ("view-bottom-screen", !view_bottom);

		return true;
	}
}
