// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.DesktopIcon : Object, Icon {
	private GLib.Icon icon;

	public DesktopIcon (GLib.Icon icon) {
		this.icon = icon;
	}

	public GLib.Icon? get_icon () {
		return icon;
	}
}
