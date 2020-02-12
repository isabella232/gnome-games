// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.CollectionView : Object, UiView {
	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	public signal void game_activated (Game game);

	private CollectionBox box;
	private CollectionHeaderBar header_bar;

	public Gtk.Widget content_box {
		get { return box; }
	}

	public Gtk.Widget title_bar {
		get { return header_bar; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active)
				search_mode = false;

			konami_code.reset ();
		}
	}

	public Gtk.Window window { get; construct; }
	public GameModel game_model { get; construct; }

	public bool loading_notification { get; set; }
	public bool search_mode { get; set; }
	public bool is_collection_empty { get; set; }

	public bool is_folded { get; set; }
	public bool is_showing_bottom_bar { get; set; }
	public bool is_subview_open { get; set; }
	public string subview_title { get; set; }

	private KonamiCode konami_code;

	construct {
		box = new CollectionBox (game_model);
		header_bar = new CollectionHeaderBar ();
		box.game_activated.connect (game => {
			game_activated (game);
		});

		is_collection_empty = game_model.get_n_items () == 0;
		game_model.items_changed.connect (() => {
			is_collection_empty = game_model.get_n_items () == 0;
		});

		header_bar.viewstack = box.viewstack;

		bind_property ("loading-notification", box,
		               "loading-notification", BindingFlags.DEFAULT);

		bind_property ("search-mode", box,
		               "search-mode", BindingFlags.BIDIRECTIONAL);
		bind_property ("search-mode", header_bar,
		               "search-mode", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-collection-empty", box,
		               "is-collection-empty", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
		bind_property ("is-collection-empty", header_bar,
		               "is-collection-empty", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

		bind_property ("is-folded", box,
		               "is-folded", BindingFlags.BIDIRECTIONAL);
		bind_property ("is-folded", header_bar,
		               "is-folded", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-showing-bottom-bar", box,
		               "is-showing-bottom-bar", BindingFlags.BIDIRECTIONAL);
		bind_property ("is-showing-bottom-bar", header_bar,
		               "is-showing-bottom-bar", BindingFlags.BIDIRECTIONAL);

		bind_property ("is-subview-open", box,
		               "is-subview-open", BindingFlags.BIDIRECTIONAL);
		bind_property ("is-subview-open", header_bar,
		               "is-subview-open", BindingFlags.BIDIRECTIONAL);

		bind_property ("subview-title", box,
		               "subview-title", BindingFlags.BIDIRECTIONAL);
		bind_property ("subview-title", header_bar,
		               "subview-title", BindingFlags.BIDIRECTIONAL);

		konami_code = new KonamiCode (window);
		konami_code.code_performed.connect (on_konami_code_performed);
	}

	public CollectionView (Gtk.Window window, GameModel game_model) {
		Object (window: window, game_model: game_model);
	}

	public void show_error (string error_message) {
		box.show_error (error_message);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (window.get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((window.get_direction () == Gtk.TextDirection.LTR) && keyval == Gdk.Key.Left) ||
		     ((window.get_direction () == Gtk.TextDirection.RTL) && keyval == Gdk.Key.Right)) &&
		     is_subview_open) {
			is_subview_open = false;

			return true;
		}

		if ((keyval == Gdk.Key.f || keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK &&
		    !is_collection_empty) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		return box.search_bar_handle_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return window.is_active && box.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return window.is_active && box.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return window.is_active && box.gamepad_absolute_axis_event (event);
	}

	private void on_konami_code_performed () {
		if (!is_view_active)
			return;

		try {
			Gtk.show_uri_on_window (window, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void run_search (string query) {
		search_mode = true;
		box.run_search (query);
	}
}
