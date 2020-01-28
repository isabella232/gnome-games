// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Runner : Object {
	public signal void new_savestate_created ();
	public signal void stopped ();

	public abstract bool can_fullscreen { get; }
	public abstract bool can_resume { get; }
	public abstract bool supports_savestates { get; }
	public abstract bool can_support_savestates { get; } // Now or in the future
	public abstract MediaSet? media_set { get; }
	public abstract InputMode input_mode { get; set; }

	public abstract Gtk.Widget get_display ();
	public abstract Gtk.Widget? get_extra_widget ();

	public abstract bool try_init_phase_one (out string error_message);
	public abstract void start () throws Error;
	public abstract void restart ();
	public abstract void resume ();
	public abstract void pause ();
	public abstract void stop ();

	public abstract Savestate? try_create_savestate (bool is_automatic);
	public abstract void delete_savestate (Savestate savestate);
	public abstract void preview_savestate (Savestate savestate);
	public abstract void preview_current_state ();
	public abstract void load_previewed_savestate () throws Error;
	public abstract Savestate[] get_savestates ();

	public abstract InputMode[] get_available_input_modes ();
	public abstract bool key_press_event (uint keyval, Gdk.ModifierType state);
	public abstract bool gamepad_button_press_event (uint16 button);
}
