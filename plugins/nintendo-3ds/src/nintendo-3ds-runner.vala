// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.Nintendo3DsRunner : RetroRunner {
	// Map the 1,2,3,4 key values to the 4 screen layouts of the Nintendo 3DS
	private static HashTable<uint, ScreenLayout?> layouts;

	private const string SCREENS_LAYOUT_OPTION = "citra_layout_option";
	private const string PROMINENT_SCREEN_OPTION = "citra_swap_screen";

	private ScreenLayout _screen_layout;
	public ScreenLayout screen_layout {
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
		layouts = new HashTable<uint, ScreenLayout?> (direct_hash, direct_equal);

		layouts[Gdk.Key.@1] = ScreenLayout.TOP_BOTTOM;
		layouts[Gdk.Key.@2] = ScreenLayout.LEFT_RIGHT;
		layouts[Gdk.Key.@3] = ScreenLayout.RIGHT_LEFT;
		layouts[Gdk.Key.@4] = ScreenLayout.QUICK_SWITCH;
	}

	public Nintendo3DsRunner (Game game, RetroCoreSource source) {
		base.from_source (game, source);
	}

	private bool core_supports_layouts () {
		var core = get_core ();

		return core != null && core.has_option (SCREENS_LAYOUT_OPTION) && core.has_option (PROMINENT_SCREEN_OPTION);
	}

	private void update_screen_layout () {
		if (!core_supports_layouts ())
			return;

		var core = get_core ();

		var screens_layout_option = core.get_option (SCREENS_LAYOUT_OPTION);
		var prominent_screen_option = core.get_option (PROMINENT_SCREEN_OPTION);

		var screens_layout_option_value = Nintendo3DsLayout.get_option_value (screen_layout);
		bool use_bottom_screen = false;

		if (screen_layout == ScreenLayout.RIGHT_LEFT)
			use_bottom_screen = true;

		if (screen_layout == ScreenLayout.QUICK_SWITCH)
			use_bottom_screen = view_bottom_screen;

		try {
			screens_layout_option.set_value (screens_layout_option_value);
			prominent_screen_option.set_value (use_bottom_screen ? "Bottom" : "Top");
		}
		catch (Error e) {
			critical ("Failed to set Citra option: %s", e.message);
		}
	}

	public override HeaderBarWidget? get_extra_widget () {
		if (!core_supports_layouts ())
			return null;

		var switcher = new ScreenLayoutSwitcher ();

		bind_property ("screen-layout", switcher, "screen-layout",
		               BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bind_property ("view-bottom-screen", switcher, "view-bottom-screen",
		               BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

		return switcher;
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

		if (screen_layout != ScreenLayout.QUICK_SWITCH)
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
		if (screen_layout != ScreenLayout.QUICK_SWITCH)
			return false;

		view_bottom_screen = !view_bottom_screen;

		return true;
	}
}
