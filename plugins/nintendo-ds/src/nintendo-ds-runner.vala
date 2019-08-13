// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.NintendoDsRunner : RetroRunner {
	private Settings settings;
	private ulong settings_changed_id;

	// Map the 1,2,3,4 key values to the 4 screen layouts of the Nintendo DS
	private static HashTable<uint, NintendoDsLayout?> layouts;

	private const string SCREENS_LAYOUT_OPTION = "desmume_screens_layout";

	static construct {
		layouts = new HashTable<uint, NintendoDsLayout?> (direct_hash, direct_equal);

		layouts[Gdk.Key.@1] = NintendoDsLayout.TOP_BOTTOM;
		layouts[Gdk.Key.@2] = NintendoDsLayout.LEFT_RIGHT;
		layouts[Gdk.Key.@3] = NintendoDsLayout.RIGHT_LEFT;
		layouts[Gdk.Key.@4] = NintendoDsLayout.QUICK_SWITCH;
	}

	construct {
		game_init.connect (on_init);
		game_deinit.connect (on_deinit);
	}

	private bool core_supports_layouts () {
		var core = get_core ();

		return core != null && core.has_option (SCREENS_LAYOUT_OPTION);
	}

	private void on_init () {
		settings = new Settings ("org.gnome.Games.plugins.nintendo-ds");
		settings_changed_id = settings.changed.connect (on_changed);

		var core = get_core ();

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

		var core = get_core ();

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

	public override Gtk.Widget? get_extra_widget () {
		if (!core_supports_layouts ())
			return null;

		return new NintendoDsLayoutSwitcher ();
	}

	public override bool key_press_event (Gdk.EventKey event) {
		// First check for Alt + 1|2|3|4
		// These shortcuts change the screen layout
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();
		if ((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) {
			// Alt key is pressed

			var shortcut_layout = layouts[event.keyval];
			if (shortcut_layout != null) {
				settings.set_string ("screen-layout", shortcut_layout.get_value ());

				return true;
			}
		}

		var layout = settings.get_string ("screen-layout");

		if (layout != "quick switch")
			return false;

		var view_bottom = settings.get_boolean ("view-bottom-screen");
		var switch_keyval = view_bottom ? Gdk.Key.Page_Up : Gdk.Key.Page_Down;
		if (event.keyval == switch_keyval)
			return swap_screens ();

		return false;
	}

	public override bool gamepad_button_press_event (uint16 button) {
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
