// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.PreferencesPagePlatformsRetroRow : Hdy.ComboRow {
	public RetroPlatform platform { get; construct; }

	private ListStore model;

	public PreferencesPagePlatformsRetroRow (RetroPlatform platform) {
		Object (platform: platform);
	}

	construct {
		title = platform.get_name ();

		/* Translators: This is displayed under the platform name when no
		 * core is available for this platform. To see this message, click
		 * on the hamburger menu, click on Preferences, then on Platforms */
		subtitle = _("None");
		use_subtitle = true;

		model = new ListStore (typeof (Retro.CoreDescriptor));

		var core_manager = RetroCoreManager.get_instance ();
		var cores = core_manager.get_cores_for_platform (platform);

		foreach (var core in cores)
			model.append (core);

		notify["selected-index"].connect (notify_selected_index_cb);

		bind_name_model (model, get_core_name);
	}

	private string get_core_name (Object object) {
		assert (object is Retro.CoreDescriptor);

		var core = object as Retro.CoreDescriptor;

		try {
			return core.get_name ();
		}
		catch (Error e) {
			return core.get_id ();
		}
	}

	private void notify_selected_index_cb () {
		var core = model.get_item (selected_index) as Retro.CoreDescriptor;

		var core_manager = RetroCoreManager.get_instance ();
		core_manager.set_preferred_core (platform, core);
	}
}
