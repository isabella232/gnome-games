// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.CommandRunner : Object, Runner {
	public bool can_fullscreen {
		get { return false; }
	}

	public bool can_resume {
		get { return false; }
	}

	public bool supports_snapshots {
		get { return false; }
	}

	public bool is_integrated {
		get { return false; }
	}

	public MediaSet? media_set {
		get { return null; }
	}

	public InputMode input_mode {
		get { return InputMode.NONE; }
		set { }
	}

	private string[] args;

	public CommandRunner (string[] args) {
		this.args = args;
	}

	public void prepare () throws RunnerError {
		if (args.length <= 0)
			throw new RunnerError.INVALID_GAME ("The game doesn’t have a valid command.");
	}

	public Gtk.Widget get_display () {
		return new RemoteDisplay ();
	}

	public HeaderBarWidget? get_extra_widget () {
		return null;
	}

	public void preview_current_state () {
	}

	public void preview_snapshot (Snapshot snapshot) {
	}

	public void load_previewed_snapshot() {
	}

	public Snapshot[] get_snapshots () {
		return {};
	}

	public void start () throws Error {
		string? working_directory = null;
		string[]? envp = null;
		var flags = SpawnFlags.SEARCH_PATH;
		SpawnChildSetupFunc? child_setup = null;
		Pid pid;

		string[] command = {};
		if (Application.is_running_in_flatpak ())
			command = { "flatpak-spawn", "--host" };
		foreach (var arg in args)
			command += arg;

		try {
			var result = Process.spawn_async (
				working_directory, command, envp, flags, child_setup, out pid);
			if (!result)
				throw new CommandError.EXECUTION_FAILED ("Couldn’t run “%s”: execution failed.", args[0]);
		}
		catch (SpawnError e) {
			warning ("%s\n", e.message);
		}
	}

	public void resume () {
	}

	public void pause () {
	}

	public void stop () {
	}

	public Snapshot? try_create_snapshot (bool is_automatic) {
		return null;
	}

	public void delete_snapshot (Snapshot snapshot) {
	}

	public InputMode[] get_available_input_modes () {
		return { };
	}

	public bool key_press_event (uint keyval, Gdk.ModifierType state) {
		return false;
	}

	public bool gamepad_button_press_event (uint16 button) {
		return false;
	}
}
