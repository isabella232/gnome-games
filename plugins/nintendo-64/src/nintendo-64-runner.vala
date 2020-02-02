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

	public Nintendo64Runner (Game game, RetroCoreSource source) {
		base.from_source (game, source);
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

	public override HeaderBarWidget? get_extra_widget () {
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

	protected override void save_to_snapshot (Snapshot snapshot) throws Error {
		base.save_to_snapshot (snapshot);

		assert (snapshot is Nintendo64Snapshot);

		var n64_snapshot = snapshot as Nintendo64Snapshot;
		n64_snapshot.pak1 = pak1;
		n64_snapshot.pak2 = pak2;
		n64_snapshot.pak3 = pak3;
		n64_snapshot.pak4 = pak4;
	}

	protected override void load_from_snapshot (Snapshot snapshot) throws Error {
		base.load_from_snapshot (snapshot);

		assert (snapshot is Nintendo64Snapshot);

		var n64_snapshot = snapshot as Nintendo64Snapshot;
		pak1 = n64_snapshot.pak1;
		pak2 = n64_snapshot.pak2;
		pak3 = n64_snapshot.pak3;
		pak4 = n64_snapshot.pak4;
	}

	protected override void reset_with_snapshot (Snapshot? last_snapshot) throws Error {
		base.reset_with_snapshot (last_snapshot);

		if (last_snapshot == null) {
			pak1 = Nintendo64Pak.MEMORY;
			pak2 = Nintendo64Pak.MEMORY;
			pak3 = Nintendo64Pak.MEMORY;
			pak4 = Nintendo64Pak.MEMORY;

			return;
		}

		assert (last_snapshot is Nintendo64Snapshot);

		var n64_snapshot = last_snapshot as Nintendo64Snapshot;
		pak1 = n64_snapshot.pak1;
		pak2 = n64_snapshot.pak2;
		pak3 = n64_snapshot.pak3;
		pak4 = n64_snapshot.pak4;
	}
}
