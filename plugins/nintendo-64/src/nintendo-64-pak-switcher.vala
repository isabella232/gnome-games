// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-64/ui/nintendo-64-pak-switcher.ui")]
private class Games.Nintendo64PakSwitcher : Gtk.Bin {
	[GtkChild]
	private Gtk.Box controllers_box;

	public Nintendo64Runner runner { get; construct; }

	public Nintendo64Pak pak1 { get; set; }
	public Nintendo64Pak pak2 { get; set; }
	public Nintendo64Pak pak3 { get; set; }
	public Nintendo64Pak pak4 { get; set; }

	public override void constructed () {
		update_ui ();

		bind_property ("pak1", runner,
		               "pak1", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bind_property ("pak2", runner,
		               "pak2", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bind_property ("pak3", runner,
		               "pak3", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		bind_property ("pak4", runner,
		               "pak4", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

		base.constructed ();
	}

	public Nintendo64PakSwitcher (Nintendo64Runner runner) {
		Object (runner: runner);
	}

	[GtkCallback]
	private void update_ui () {
		foreach (var row in controllers_box.get_children ())
			controllers_box.remove (row);

		var core = runner.get_core ();
		var iterator = core.iterate_controllers ();

		Nintendo64PakPlayer first_widget = null;
		uint total_players = 0;

		uint port;
		unowned Retro.Controller controller;
		while (iterator.next (out port, out controller)) {
			if (total_players > 3)
				break;

			total_players++;

			bool supports_rumble = controller.get_supports_rumble ();
			var widget = new Nintendo64PakPlayer (total_players, supports_rumble);

			if (first_widget == null)
				first_widget = widget;

			bind_property (@"pak$total_players", widget, "pak",
                           BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

			controllers_box.add (widget);
		}

		if (total_players == 1)
			first_widget.show_title = false;
	}
}
