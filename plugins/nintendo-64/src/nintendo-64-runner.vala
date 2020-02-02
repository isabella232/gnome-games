// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.Nintendo64Runner : RetroRunner {
	private const string MUPEN64PLUS_PAK_OPTION = "mupen64plus-pak%u";
	private const string PARALLEL_N64_PAK_OPTION = "parallel-n64-pak%u";

	private Nintendo64Pak pak[4];

	public Nintendo64Pak pak1 {
		get { return pak[0]; }
		set {
			pak[0] = value;
			update_paks ();
		}
	}

	public Nintendo64Pak pak2 {
		get { return pak[1]; }
		set {
			pak[1] = value;
			update_paks ();
		}
	}

	public Nintendo64Pak pak3 {
		get { return pak[2]; }
		set {
			pak[2] = value;
			update_paks ();
		}
	}

	public Nintendo64Pak pak4 {
		get { return pak[3]; }
		set {
			pak[3] = value;
			update_paks ();
		}
	}

	private bool has_pak_options (string prefix) {
		var core = get_core ();

		for (int i = 1; i <= 4; i++)
			if (!core.has_option (prefix.printf (i)))
				return false;

		return true;
	}

	private string? get_option_prefix () {
		if (has_pak_options (MUPEN64PLUS_PAK_OPTION))
			return MUPEN64PLUS_PAK_OPTION;

		if (has_pak_options (PARALLEL_N64_PAK_OPTION))
			return PARALLEL_N64_PAK_OPTION;

		return null;
	}

	public override Gtk.Widget? get_extra_widget () {
		if (get_option_prefix () == null)
			return null;

		return new Nintendo64PakSwitcher (this);
	}

	private void update_paks () {
		var prefix = get_option_prefix ();

		if (prefix == null)
			return;

		var core = get_core ();
		for (int i = 0; i < 4; i++) {
			var option = core.get_option (prefix.printf (i + 1));

			try {
				option.set_value (pak[i].get_value ());
			}
			catch (Error e) {
				critical ("Couldn't set pak %u to %s: %s", i + 1, pak[i].get_value (), e.message);
			}
		}
	}

	protected override void save_savestate_metadata (Savestate savestate) throws Error {
		assert (savestate is Nintendo64Savestate);

		var platform_savestate = savestate as Nintendo64Savestate;
		platform_savestate.pak1 = pak1;
		platform_savestate.pak2 = pak2;
		platform_savestate.pak3 = pak3;
		platform_savestate.pak4 = pak4;

		base.save_savestate_metadata (savestate);
	}

	protected override void load_savestate_metadata (Savestate savestate) throws Error {
		base.load_savestate_metadata (savestate);

		assert (savestate is Nintendo64Savestate);

		var platform_savestate = savestate as Nintendo64Savestate;
		pak1 = platform_savestate.pak1;
		pak2 = platform_savestate.pak2;
		pak3 = platform_savestate.pak3;
		pak4 = platform_savestate.pak4;
	}

	protected override void reset_metadata (Savestate last_savestate) throws Error {
		base.reset_metadata (last_savestate);

		if (last_savestate == null) {
			pak1 = Nintendo64Pak.MEMORY;
			pak2 = Nintendo64Pak.MEMORY;
			pak3 = Nintendo64Pak.MEMORY;
			pak4 = Nintendo64Pak.MEMORY;
			return;
		}

		assert (last_savestate is Nintendo64Savestate);

		var platform_savestate = last_savestate as Nintendo64Savestate;
		pak1 = platform_savestate.pak1;
		pak2 = platform_savestate.pak2;
		pak3 = platform_savestate.pak3;
		pak4 = platform_savestate.pak4;
	}
}
