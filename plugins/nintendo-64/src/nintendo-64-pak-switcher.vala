// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-64/nintendo-64-pak-switcher.ui")]
private class Games.Nintendo64PakSwitcher : Gtk.Bin, HeaderBarWidget {
	[GtkChild]
	private unowned Gtk.MenuButton menu_button;
	[GtkChild]
	private unowned Gtk.Box controllers_box;

	public Nintendo64Runner runner { get; construct; }

	public Nintendo64Pak pak1 { get; set; }
	public Nintendo64Pak pak2 { get; set; }
	public Nintendo64Pak pak3 { get; set; }
	public Nintendo64Pak pak4 { get; set; }

	private bool is_menu_open;
	public bool block_autohide {
		get { return is_menu_open; }
	}

	public override void constructed () {
		update_ui ();

		runner.controllers_changed.connect (update_ui);

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
	private void on_menu_state_changed () {
		is_menu_open = menu_button.active;
		notify_property ("block-autohide");
	}

	private void update_ui () {
		foreach (var row in controllers_box.get_children ())
			controllers_box.remove (row);

		var core = runner.get_core ();
		var iterator = core.iterate_controllers ();

		Nintendo64PakController first_widget = null;
		uint n_players = 0;

		uint port;
		unowned Retro.Controller controller;
		while (iterator.next (out port, out controller)) {
			if (n_players > 3)
				break;

			n_players++;

			var widget = new Nintendo64PakController (controller, port);

			if (first_widget == null)
				first_widget = widget;

			bind_property (@"pak$(port + 1)", widget, "pak",
			               BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

			controllers_box.add (widget);
		}

		if (n_players == 1)
			first_widget.show_title = false;
	}
}
