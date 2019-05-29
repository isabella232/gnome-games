// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/error-info-bar.ui")]
private class Games.ErrorInfoBar : Gtk.Bin {
	[GtkChild]
	private Gtk.InfoBar info_bar;
	[GtkChild]
	private Gtk.Label label;

	[GtkCallback]
	private void on_response () {
		info_bar.revealed = false;
	}

	public void show_error (string message) {
		label.label = message;
		info_bar.revealed = true;
	}
}
