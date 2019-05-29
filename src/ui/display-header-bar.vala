// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-header-bar.ui")]
private class Games.DisplayHeaderBar : Gtk.Bin {
	public signal void back ();

	[GtkChild]
	private MediaMenuButton media_button;

	public string game_title {
		set { header_bar.title = value; }
	}

	public bool show_title_buttons {
		set { header_bar.show_close_button = value; }
	}

	public bool can_fullscreen { get; set; }
	public bool is_fullscreen { get; set; }

	public MediaSet? media_set {
		set { media_button.media_set = value; }
	}

	[GtkChild]
	private InputModeSwitcher input_mode_switcher;
	private Runner _runner;
	public Runner runner {
		get { return _runner; }
		set {
			_runner = value;
			input_mode_switcher.runner = value;

			if (runner != null)
				extra_widget = runner.get_extra_widget ();
			else
				extra_widget = null;
		}
	}

	private Gtk.Widget _extra_widget;
	private Gtk.Widget extra_widget {
		get { return _extra_widget; }
		set {
			if (extra_widget == value)
				return;

			if (extra_widget != null)
				remove (extra_widget);

			_extra_widget = value;

			if (extra_widget != null)
				header_bar.pack_end (extra_widget);
		}
	}

	[GtkChild]
	private Gtk.HeaderBar header_bar;
	[GtkChild]
	private Gtk.Button fullscreen;
	[GtkChild]
	private Gtk.Button restore;

	private Settings settings;

	construct {
		settings = new Settings ("org.gnome.Games");
	}

	[GtkCallback]
	private void on_fullscreen_changed () {
		fullscreen.visible = can_fullscreen && !is_fullscreen;
		restore.visible = can_fullscreen && is_fullscreen;
	}

	[GtkCallback]
	private void on_back_clicked () {
		back ();
	}

	[GtkCallback]
	private void on_fullscreen_clicked () {
		is_fullscreen = true;
		settings.set_boolean ("fullscreen", true);
	}

	[GtkCallback]
	private void on_restore_clicked () {
		is_fullscreen = false;
		settings.set_boolean ("fullscreen", false);
	}
}
