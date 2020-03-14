// This file is part of GNOME Games. License: GPL-3.0+.

public interface Games.Runner : Object {
	public signal void snapshot_created ();
	public signal void stopped ();
	public signal void crash (string message);

	public abstract bool can_fullscreen { get; }
	public abstract bool can_resume { get; }
	public abstract bool supports_snapshots { get; }
	public abstract bool is_integrated { get; }
	public abstract MediaSet? media_set { get; }
	public abstract InputMode input_mode { get; set; }

	public abstract Gtk.Widget get_display ();
	public abstract HeaderBarWidget? get_extra_widget ();

	public abstract void prepare () throws RunnerError;
	public abstract void start () throws Error;
	public abstract void resume ();
	public abstract void pause ();
	public abstract void stop ();

	public abstract Snapshot? try_create_snapshot (bool is_automatic);
	public abstract void delete_snapshot (Snapshot snapshot);
	public abstract void preview_snapshot (Snapshot snapshot);
	public abstract void preview_current_state ();
	public abstract void load_previewed_snapshot () throws Error;
	public abstract Snapshot[] get_snapshots ();

	public abstract InputMode[] get_available_input_modes ();
	public abstract bool key_press_event (uint keyval, Gdk.ModifierType state);
	public abstract bool gamepad_button_press_event (uint16 button);
}
