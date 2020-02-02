// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/plugins/nintendo-64/ui/nintendo-64-pak-player.ui")]
private class Games.Nintendo64PakPlayer : Gtk.Box {
	[GtkChild]
	private Gtk.Label title;
	[GtkChild]
	private Gtk.ModelButton memory_btn;
	[GtkChild]
	private Gtk.ModelButton rumble_btn;

	public uint player { get; construct; }
	public bool supports_rumble { get; construct; }
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

	public Nintendo64PakPlayer (uint player, bool supports_rumble) {
		Object (player: player, supports_rumble: supports_rumble);
	}

	construct {
		title.label = _("Player %u").printf (player);
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
