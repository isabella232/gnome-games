// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.NintendoDsRunner : RetroRunner {
	// Map the 1,2,3,4 key values to the 4 screen layouts of the Nintendo DS
	private static HashTable<uint, NintendoDsLayout?> layouts;
	private static HashTable<string, string> gap_overrides;

	private const string SCREENS_LAYOUT_OPTION = "desmume_screens_layout";
	private const string SCREENS_GAP_OPTION = "desmume_screens_gap";
	private const string SCREENS_GAP_NONE = "0";
	private const string SCREENS_GAP_DEFAULT = "80";

	private const size_t HEADER_GAME_CODE_OFFSET = 12;
	private const size_t HEADER_GAME_CODE_SIZE = 3;

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

		gap_overrides = new HashTable<string, string> (str_hash, str_equal);

		try {
			var bytes = resources_lookup_data ("/org/gnome/Games/plugins/nintendo-ds/layout-overrides", ResourceLookupFlags.NONE);
			var text = (string) bytes.get_data ();
			var lines = text.split ("\n");

			foreach (var line in lines) {
				var data = line.split ("#", 2);
				if (data.length < 2)
					continue;

				var fields = data[0].strip ().split (" ", 2);
				if (fields.length < 2)
					continue;

				var key = fields[0];
				var value = fields[1];
				gap_overrides[key] = value;
			}
		}
		catch (Error e) {
			critical ("Couldn't read layout overrides: %s", e.message);
		}
	}

	public NintendoDsRunner (Game game, RetroCoreSource source) {
		base.from_source (game, source);
	}

	private bool core_supports_layouts () {
		var core = get_core ();

		return core != null && core.has_option (SCREENS_LAYOUT_OPTION) && core.has_option (SCREENS_GAP_OPTION);
	}

	private string get_screen_gap_width () {

		try {
			assert (media_set.get_size () == 1);
			var uris = media_set.get_media (0).get_uris ();
			var file = uris[0].to_file ();
			var stream = new StringInputStream (file);
			string game_code = stream.read_string_for_size (HEADER_GAME_CODE_OFFSET, HEADER_GAME_CODE_SIZE);

			return gap_overrides[game_code] ?? SCREENS_GAP_DEFAULT;
		}
		catch (Error e) {
			critical ("Couldn't read the header: %s", e.message);

			return SCREENS_GAP_DEFAULT;
		}
	}

	private void update_screen_layout () {
		if (!core_supports_layouts ())
			return;

		var core = get_core ();

		var screens_layout_option = core.get_option (SCREENS_LAYOUT_OPTION);
		var screens_layout_option_value = screen_layout.get_value ();
		if (screen_layout == NintendoDsLayout.QUICK_SWITCH)
			screens_layout_option_value = view_bottom_screen ? "bottom only" : "top only";

		var screens_gap_option = core.get_option (SCREENS_GAP_OPTION);
		string screens_gap;
		if (screen_layout == NintendoDsLayout.TOP_BOTTOM)
			screens_gap = get_screen_gap_width ();
		else
			screens_gap = SCREENS_GAP_NONE;

		try {
			screens_layout_option.set_value (screens_layout_option_value);
			screens_gap_option.set_value (screens_gap);
		}
		catch (Error e) {
			critical ("Failed to set desmume option: %s", e.message);
		}
	}

	public override HeaderBarWidget? get_extra_widget () {
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

	protected override void save_to_snapshot (Savestate savestate) throws Error {
		base.save_to_snapshot (savestate);

		assert (savestate is NintendoDsSnapshot);

		var ds_savestate = savestate as NintendoDsSnapshot;
		ds_savestate.screen_layout = screen_layout;
		ds_savestate.view_bottom_screen = view_bottom_screen;
	}

	protected override void load_from_snapshot (Savestate savestate) throws Error {
		base.load_from_snapshot (savestate);

		assert (savestate is NintendoDsSnapshot);

		var ds_savestate = savestate as NintendoDsSnapshot;
		screen_layout = ds_savestate.screen_layout;
		view_bottom_screen = ds_savestate.view_bottom_screen;
	}

	protected override void reset_with_snapshot (Savestate? last_savestate) throws Error {
		base.reset_with_snapshot (last_savestate);

		screen_layout = NintendoDsLayout.TOP_BOTTOM;
		view_bottom_screen = false;
	}
}
