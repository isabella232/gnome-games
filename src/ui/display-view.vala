// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/display-view.ui")]
private class Games.DisplayView: Gtk.Bin, ApplicationView {
	public signal void back ();

	[GtkChild]
	public DisplayBox box;
	[GtkChild]
	public DisplayHeaderBar header_bar;

	public Gtk.Widget titlebar {
		get { return header_bar; }
	}

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active) {
				is_fullscreen = false;

				if (box.runner != null) {
					box.runner.stop ();
					box.runner = null;
				}
			}
		}
	}

	public ApplicationWindow window { get; construct set; }

	public bool is_fullscreen { get; set; }

	private Settings settings;

	private Binding box_fullscreen_binding;
	private Binding header_bar_fullscreen_binding;

	construct {
		settings = new Settings ("org.gnome.Games");

		box_fullscreen_binding = bind_property ("is-fullscreen", box, "is-fullscreen",
		                                        BindingFlags.BIDIRECTIONAL);
		header_bar_fullscreen_binding = bind_property ("is-fullscreen", header_bar,
		                                               "is-fullscreen",
		                                               BindingFlags.BIDIRECTIONAL);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		// Mouse button 8 is the navigation previous button
		if (event.button == 8) {
			back ();
			return true;
		}

		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		if ((event.keyval == Gdk.Key.f || event.keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK &&
		    header_bar.can_fullscreen) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (event.keyval == Gdk.Key.F11 && header_bar.can_fullscreen) {
			is_fullscreen = !is_fullscreen;
			settings.set_boolean ("fullscreen", is_fullscreen);

			return true;
		}

		if (event.keyval == Gdk.Key.Escape && header_bar.can_fullscreen) {
			is_fullscreen = false;
			settings.set_boolean ("fullscreen", false);

			return true;
		}

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((get_direction () == Gtk.TextDirection.LTR) && event.keyval == Gdk.Key.Left) ||
		     ((get_direction () == Gtk.TextDirection.RTL) && event.keyval == Gdk.Key.Right))) {
			on_display_back ();

			return true;
		}

		return false;
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return false;
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return false;
	}

	[GtkCallback]
	private void on_display_back () {
		back ();
	}
}
