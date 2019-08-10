// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-header-bar.ui")]
private class Games.DisplayHeaderBar : Gtk.Stack {
	public signal void back ();

	[GtkChild]
	private MediaMenuButton media_button;

	private SavestatesListState _savestates_list_state;
	public SavestatesListState savestates_list_state {
		get { return _savestates_list_state; }
		set {
			_savestates_list_state = value;

			if (value != null)
				value.notify["is-revealed"].connect (on_savestates_list_state_changed);
		}
	}

	public string game_title {
		set {
			ingame_header_bar.title = value;
			savestates_header_bar.title = value;
		}
	}

	public bool show_title_buttons {
		set { ingame_header_bar.show_close_button = value; }
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

			if (runner != null) {
				extra_widget = runner.get_extra_widget ();

				secondary_menu_button.sensitive = runner.supports_savestates;
				secondary_menu_button.visible = runner.can_support_savestates;
			}
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
				ingame_header_bar.remove (extra_widget);

			_extra_widget = value;

			if (extra_widget != null)
				ingame_header_bar.pack_end (extra_widget);
		}
	}

	[GtkChild]
	private Gtk.HeaderBar ingame_header_bar;
	[GtkChild]
	private Gtk.Button fullscreen;
	[GtkChild]
	private Gtk.Button restore;
	[GtkChild]
	private Gtk.MenuButton secondary_menu_button;
	[GtkChild]
	private Gtk.HeaderBar savestates_header_bar;

	private Settings settings;

	public DisplayHeaderBar (SavestatesListState savestates_list_state) {
		Object (savestates_list_state: savestates_list_state);
	}

	construct {
		settings = new Settings ("org.gnome.Games");
	}

	public void hide_secondary_menu_button () {
		secondary_menu_button.visible = false;
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

	[GtkCallback]
	private void on_secondary_menu_savestates_clicked () {
		savestates_list_state.is_revealed = true;
	}

	[GtkCallback]
	private void on_savestates_load_clicked () {
		savestates_list_state.load_clicked ();
	}

	[GtkCallback]
	private void on_savestates_delete_clicked () {
		savestates_list_state.delete_clicked ();
	}

	[GtkCallback]
	private void on_savestates_back_clicked () {
		savestates_list_state.is_revealed = false;
	}

	private void on_savestates_list_state_changed () {
		if (savestates_list_state.is_revealed)
			set_visible_child (savestates_header_bar);
		else
			set_visible_child (ingame_header_bar);
	}
}
