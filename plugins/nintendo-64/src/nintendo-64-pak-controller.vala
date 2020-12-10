// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-64/nintendo-64-pak-controller.ui")]
private class Games.Nintendo64PakController : Gtk.Box {
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.ModelButton memory_btn;
	[GtkChild]
	private Gtk.ModelButton rumble_btn;

	public Retro.Controller gamepad { get; construct; }
	public uint port { get; construct; }
	public bool show_title { get; set; default = true; }

	private Nintendo64Pak _pak;
	public Nintendo64Pak pak {
		get { return _pak; }
		set {
			_pak = value;
			memory_btn.active = (pak == Nintendo64Pak.MEMORY);
			rumble_btn.active = (pak == Nintendo64Pak.RUMBLE);
		}
	}

	public Nintendo64PakController (Retro.Controller gamepad, uint port) {
		Object (gamepad: gamepad, port: port);
	}

	construct {
		title.label = _("Player %u").printf (port + 1);
		rumble_btn.sensitive = gamepad.get_supports_rumble ();
	}

	[GtkCallback]
	public void memory_btn_clicked () {
		pak = Nintendo64Pak.MEMORY;
	}

	[GtkCallback]
	public void rumble_btn_clicked () {
		pak = Nintendo64Pak.RUMBLE;
	}
}
