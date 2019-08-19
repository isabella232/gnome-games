// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.NintendoDsRunner : RetroRunner {
	// Map the 1,2,3,4 key values to the 4 screen layouts of the Nintendo DS
	private static HashTable<uint, NintendoDsLayout?> layouts;

	private const string SCREENS_LAYOUT_OPTION = "desmume_screens_layout";

	private NintendoDsLayout _screen_layout;
	public NintendoDsLayout screen_layout {
		get { return _screen_layout; }
		set {
			_screen_layout = value;
			update_screen_layout ();
		}
	}

	private bool _view_bottom_screen;
	public bool view_bottom_screen {
		get { return _view_bottom_screen; }
		set {
			_view_bottom_screen = value;
			update_screen_layout ();
		}
	}

	static construct {
		layouts = new HashTable<uint, NintendoDsLayout?> (direct_hash, direct_equal);

		layouts[Gdk.Key.@1] = NintendoDsLayout.TOP_BOTTOM;
		layouts[Gdk.Key.@2] = NintendoDsLayout.LEFT_RIGHT;
		layouts[Gdk.Key.@3] = NintendoDsLayout.RIGHT_LEFT;
		layouts[Gdk.Key.@4] = NintendoDsLayout.QUICK_SWITCH;
	}

	construct {
		game_init.connect (on_init);
	}

	private bool core_supports_layouts () {
		var core = get_core ();

		return core != null && core.has_option (SCREENS_LAYOUT_OPTION);
	}

	private void on_init () {
		var core = get_core ();

		core.options_set.connect (update_screen_layout);
	}

	private void update_screen_layout () {
		if (!core_supports_layouts ())
			return;

		var core = get_core ();

		var option = core.get_option (SCREENS_LAYOUT_OPTION);

		var option_value = screen_layout.get_value ();
		if (screen_layout == NintendoDsLayout.QUICK_SWITCH)
			option_value = view_bottom_screen ? "bottom only" : "top only";

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

		return new NintendoDsLayoutSwitcher (this);
	}

	public override bool key_press_event (uint keyval, Gdk.ModifierType state) {
		if (state == Gdk.ModifierType.MOD1_MASK) {
			// Alt + 1|2|3|4
			var shortcut_layout = layouts[keyval];
			if (shortcut_layout != null) {
				screen_layout = shortcut_layout;

				return true;
			}
		}

		if (screen_layout != NintendoDsLayout.QUICK_SWITCH)
			return false;

		var switch_keyval = view_bottom_screen ? Gdk.Key.Page_Up : Gdk.Key.Page_Down;
		if (keyval == switch_keyval)
			return swap_screens ();

		return false;
	}

	public override bool gamepad_button_press_event (uint16 button) {
		if (button == EventCode.BTN_THUMBR)
			return swap_screens ();

		return false;
	}

	private bool swap_screens () {
		if (screen_layout != NintendoDsLayout.QUICK_SWITCH)
			return false;

		view_bottom_screen = !view_bottom_screen;

		return true;
	}

	protected override void save_extra_savestate_metadata (Savestate savestate) {
		assert (savestate is NintendoDsSavestate);

		var ds_savestate = savestate as NintendoDsSavestate;
		ds_savestate.screen_layout = screen_layout;
		ds_savestate.view_bottom_screen = view_bottom_screen;
	}

	protected override void load_extra_savestate_metadata (Savestate savestate) {
		assert (savestate is NintendoDsSavestate);

		var ds_savestate = savestate as NintendoDsSavestate;

		ds_savestate.load_extra_metadata ();
		screen_layout = ds_savestate.screen_layout;
		view_bottom_screen = ds_savestate.view_bottom_screen;
	}
}
