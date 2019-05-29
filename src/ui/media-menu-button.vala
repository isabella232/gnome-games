// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/media-menu-button.ui")]
private class Games.MediaMenuButton : Gtk.Bin {
	[GtkChild]
	private Gtk.Image media_image;
	[GtkChild]
	private Gtk.MenuButton menu_button;

	private MediaSet _media_set;
	public MediaSet media_set {
		get { return _media_set; }
		set {
			_media_set = value;

			if (media_set == null || media_set.get_size () < 2) {
				hide ();

				return;
			}

			media_image.set_from_gicon (media_set.icon, Gtk.IconSize.BUTTON);

			show ();
		}
	}

	public Gtk.Popover popover {
		set { menu_button.popover = value; }
	}
}
