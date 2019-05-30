// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunner : Object, Runner {
	public signal void game_init ();
	public signal void game_deinit ();

	public bool can_fullscreen {
		get { return true; }
	}

	public bool can_quit_safely {
		get { return !should_save; }
	}

	public bool can_resume {
		get {
			try {
				init ();

				// Check if the core can support savestates
				if (!core.get_can_access_state ())
					return false;

				// Check if there are any existing savestates
				if (game_savestates.length != 0)
					return true;
			}
			catch (Error e) {
				warning (e.message);
			}

			return false;
		}
	}

	private MediaSet _media_set;
	public MediaSet? media_set {
		get { return _media_set; }
	}

	private Retro.Core core;
	private Retro.CoreView view;
	private RetroInputManager input_manager;
	private Retro.MainLoop loop;
	private InputMode _input_mode;
	public InputMode input_mode {
		get { return _input_mode; }
		set {
			_input_mode = value;
			input_manager.input_mode = value;
		}
	}

	private Retro.CoreDescriptor core_descriptor;
	private RetroCoreSource core_source;
	private Platform platform;
	private Uid uid;
	private InputCapabilities input_capabilities;
	private Settings settings;
	private Title game_title;
	private Savestate[] game_savestates;
	private Savestate latest_savestate;

	private bool _running;
	private bool running {
		get { return _running; }
		set {
			_running = value;

			if (running)
				should_save = true;

			view.sensitive = running;
		}
	}

	private bool is_initialized;
	private bool is_ready;
	private bool should_save;

	public RetroRunnerBuilder builder {
		construct {
			core_descriptor = value.core_descriptor;
			_media_set = value.media_set;

			uid = value.uid;
			core_source = value.core_source;
			platform = value.platform;
			input_capabilities = value.input_capabilities;
			game_title = value.title;

			_media_set.notify["selected-media-number"].connect (on_media_number_changed);
		}
	}

	construct {
		is_initialized = false;
		is_ready = false;
		should_save = false;

		settings = new Settings ("org.gnome.Games");
	}

	~RetroRunner () {
		pause ();
		deinit ();
	}

	public bool check_is_valid (out string error_message) throws Error {
		try {
			media_set.selected_media_number = 0;
			init ();
		}
		catch (RetroError.MODULE_NOT_FOUND e) {
			debug (e.message);
			error_message = get_unsupported_system_message ();

			return false;
		}
		catch (RetroError.FIRMWARE_NOT_FOUND e) {
			debug (e.message);
			error_message = get_unsupported_system_message ();

			return false;
		}

		error_message = "";

		return true;
	}

	public Gtk.Widget get_display () {
		return view;
	}

	public virtual Gtk.Widget? get_extra_widget () {
		return null;
	}

	public void start () throws Error {
		if (latest_savestate != null && latest_savestate.has_media_data ())
			media_set.selected_media_number = latest_savestate.get_media_data ();

		if (!is_initialized)
			init ();

		loop.stop ();

		if (!is_ready) {
			if (latest_savestate != null)
				load_save_ram (latest_savestate.get_save_ram_path ());

			is_ready = true;
		}
		core.reset ();

		loop.start ();
		running = true;
	}

	public void resume () throws Error {
		if (!is_initialized)
			init ();

		loop.stop ();

		if (!is_ready) {
			load_latest_savestate ();
		}

		loop.start ();
		running = true;
	}

	private void load_latest_savestate () throws Error {
		// TODO: This method assumes that there exists at least a savestate
		// [Yeti]: Perhaps we should bug-proof this using an Assert ?
		load_save_ram (latest_savestate.get_save_ram_path ());
		core.reset ();
		core.set_state (latest_savestate.get_snapshot_data ());

		if (latest_savestate.has_media_data ())
			media_set.selected_media_number = latest_savestate.get_media_data ();

		is_ready = true;
	}

	private void init () throws Error {
		if (is_initialized)
			return;

		view = new Retro.CoreView ();
		settings.changed["video-filter"].connect (on_video_filter_changed);
		on_video_filter_changed ();

		prepare_core ();

		var present_analog_sticks = input_capabilities == null || input_capabilities.get_allow_analog_gamepads ();
		input_manager = new RetroInputManager (core, view, present_analog_sticks);
		// Keep the internal values of input_mode in sync between RetroRunner and RetroInputManager
		_input_mode = input_manager.input_mode;

		core.shutdown.connect (on_shutdown);

		core.run (); // Needed to finish preparing some cores.

		loop = new Retro.MainLoop (core);
		running = false;

		// Load the game's savestates if there are any
		string core_id = null;

		if (core_descriptor != null) {
			core_id = core_descriptor.get_id ();
		}
		else {
			core_id = core_source.get_core_id ();
		}

		game_savestates = Savestate.get_game_savestates (uid, core_id);
		if (game_savestates.length != 0)
			latest_savestate = game_savestates[0];

		load_screenshot ();

		is_initialized = true;
	}

	private void deinit () {
		if (!is_initialized)
			return;

		settings.changed["video-filter"].disconnect (on_video_filter_changed);

		game_deinit ();

		core = null;
		view.set_core (null);
		view = null;
		input_manager = null;
		loop = null;

		_running = false;
		is_initialized = false;
		is_ready = false;
		should_save = false;
	}

	private void on_video_filter_changed () {
		var filter_name = settings.get_string ("video-filter");
		var filter = Retro.VideoFilter.from_string (filter_name);
		view.set_filter (filter);
	}

	private void prepare_core () throws Error {
		string module_path;
		if (core_descriptor != null) {
			var module_file = core_descriptor.get_module_file ();
			if (module_file == null)
				throw new RetroError.MODULE_NOT_FOUND (_("No module found for “%s”."), core_descriptor.get_name ());

			module_path = module_file.get_path ();
		}
		else
			module_path = core_source.get_module_path ();
		core = new Retro.Core (module_path);

		var options_path = get_options_path ();
		if (FileUtils.test (options_path, FileTest.EXISTS))
			core.options_set.connect (() => {
				try {
					var options = new RetroOptions (options_path);
					options.apply (core);
				} catch (Error e) {
					critical (e.message);
				}
			});

		game_init ();

		var platforms_dir = Application.get_platforms_dir ();
		var platform_id = platform.get_id ();
		core.system_directory = @"$platforms_dir/$platform_id/system";

		if (latest_savestate != null) {
			var save_directory = latest_savestate.get_save_directory_path ();
			Application.try_make_dir (save_directory);
			core.save_directory = save_directory;
		}

		core.log.connect (Retro.g_log);
		view.set_core (core);

		string[] medias_uris = {};
		media_set.foreach_media ((media) => {
			var uris = media.get_uris ();
			medias_uris += (uris.length == 0) ? "" : uris[0].to_string ();
		});

		core.set_medias (medias_uris);
		core.boot ();
		core.set_current_media (media_set.selected_media_number);
	}

	public void pause () {
		if (!is_initialized)
			return;

		loop.stop ();

		//FIXME:
		// In the future here there will be code which updates the currently
		// used temporary savestate

		running = false;
	}

	public void stop () {
		if (!is_initialized)
			return;

		pause ();

		try {
			attempt_create_savestate ();
		}
		catch (Error e) {
			warning (e.message);
		}

		deinit ();

		stopped ();
	}

	public InputMode[] get_available_input_modes () {
		if (input_capabilities == null)
			return { InputMode.GAMEPAD };

		if (input_capabilities.get_allow_keyboard_mode ())
			return { InputMode.GAMEPAD, InputMode.KEYBOARD };
		else
			return { InputMode.GAMEPAD };
	}

	public virtual bool key_press_event (Gdk.EventKey event) {
		return false;
	}

	public virtual bool gamepad_button_press_event (uint16 button) {
		return false;
	}

	private void on_media_number_changed () {
		if (!is_initialized)
			return;

		try {
			core.set_current_media (media_set.selected_media_number);
		}
		catch (Error e) {
			debug (e.message);

			return;
		}

		var media_number = media_set.selected_media_number;

		Media media = null;
		try {
			media = media_set.get_selected_media (media_number);
		}
		catch (Error e) {
			warning (e.message);

			return;
		}

		var uris = media.get_uris ();
		if (uris.length == 0)
			return;

		try {
			core.set_current_media (media_set.selected_media_number);
		}
		catch (Error e) {
			debug (e.message);

			return;
		}
	}

	private string get_game_savestates_dir_path () throws Error {
		// Get the savestates directory of the game
		var data_dir_path = Application.get_data_dir ();
		var savestates_dir_path = Path.build_filename (data_dir_path, "savestates");
		var uid = uid.get_uid ();

		string core_id = null;

		if (core_descriptor != null) {
			core_id = core_descriptor.get_id ();
		}
		else {
			core_id = core_source.get_core_id ();
		}

		var core_id_prefix = core_id.replace (".libretro", "");

		return Path.build_filename (savestates_dir_path, uid + "-" + core_id_prefix);
	}

	public void attempt_create_savestate () throws Error {
		if (!should_save)
			return;

		// Create a new savestate
		var game_savestates_dir_path = get_game_savestates_dir_path ();
		var now_time_str = TimeVal ().to_iso8601 ();
		var new_savestate_path = Path.build_filename (game_savestates_dir_path, now_time_str);
		var new_savestate_dir = File.new_for_path (new_savestate_path);

		new_savestate_dir.make_directory ();

		store_save_ram (new_savestate_dir);

		if (media_set.get_size () > 1)
			save_media_data (new_savestate_dir);

		if (!core.get_can_access_state ())
			return;

		save_snapshot (new_savestate_dir);
		save_screenshot (new_savestate_dir);

		should_save = false;
	}

	private string get_options_path () throws Error {
		assert (core != null);

		var core_filename = core.get_filename ();
		var file = File.new_for_path (core_filename);
		var basename = file.get_basename ();
		var options_name = basename.split (".")[0];
		options_name = options_name.replace ("_libretro", "");

		return @"$(Config.OPTIONS_DIR)/$options_name.options";
	}

	private void store_save_ram (File savestate_dir) throws Error{
		var bytes = core.get_memory (Retro.MemoryType.SAVE_RAM);
		var save = bytes.get_data ();
		if (save.length == 0)
			return;

		var savestate_dir_path = savestate_dir.get_path ();
		var save_ram_path = Path.build_filename (savestate_dir_path, "save");

		FileUtils.set_data (save_ram_path, save);
	}

	private void load_save_ram (string save_ram_path) throws Error {
		if (!FileUtils.test (save_ram_path, FileTest.EXISTS))
			return;

		uint8[] data = null;
		FileUtils.get_data (save_ram_path, out data);

		var expected_size = core.get_memory_size (Retro.MemoryType.SAVE_RAM);
		if (data.length != expected_size)
			warning ("Unexpected RAM data size: got %lu, expected %lu\n", data.length, expected_size);

		var bytes = new Bytes.take (data);
		core.set_memory (Retro.MemoryType.SAVE_RAM, bytes);
	}

	private void save_snapshot (File savestate_dir) throws Error {
		var bytes = core.get_state ();
		var buffer = bytes.get_data ();

		var savestate_dir_path = savestate_dir.get_path ();
		var snapshot_path = Path.build_filename (savestate_dir_path, "snapshot");

		FileUtils.set_data (snapshot_path, buffer);
	}

	private void save_media_data (File savestate_dir) throws Error {
		var savestate_dir_path = savestate_dir.get_path ();
		var media_path = Path.build_filename (savestate_dir_path, "media");

		string contents = media_set.selected_media_number.to_string ();

		FileUtils.set_contents (media_path, contents, contents.length);
	}

	private void save_screenshot (File savestate_dir) throws Error {
		if (!core.get_can_access_state ())
			return;

		var pixbuf = view.get_pixbuf ();
		if (pixbuf == null)
			return;

		var savestate_dir_path = savestate_dir.get_path ();
		var screenshot_path = Path.build_filename (savestate_dir_path, "screenshot");

		var now = new GLib.DateTime.now_local ();
		var creation_time = now.to_string ();
		var platform_name = platform.get_name ();
		var platform_id = platform.get_id ();
		if (platform_name == null) {
			critical ("Unknown name for platform %s", platform_id);
			platform_name = _("Unknown platform");
		}
		var title = game_title.get_title ();

		var x_dpi = pixbuf.get_option ("x-dpi") ?? "";
		var y_dpi = pixbuf.get_option ("y-dpi") ?? "";

		// See http://www.libpng.org/pub/png/spec/iso/index-object.html#11textinfo
		// for description of used keys. "Game Title" and "Platform" are
		// non-standard fields as allowed by PNG specification.
		pixbuf.save (screenshot_path, "png",
		             "tEXt::Software", "GNOME Games",
		             "tEXt::Title", @"Screenshot of $title on $platform_name",
		             "tEXt::Creation Time", creation_time.to_string (),
		             "tEXt::Game Title", title,
		             "tEXt::Platform", platform_name,
		             "x-dpi", x_dpi,
		             "y-dpi", y_dpi,
		             null);
	}

	private void load_screenshot () throws Error {
		if (!core.get_can_access_state ())
			return;

		if (game_savestates.length == 0)
			return;

		// Load the screenshot of the latest savestate
		var screenshot_path = latest_savestate.get_screenshot_path ();

		if (!FileUtils.test (screenshot_path, FileTest.EXISTS))
			return;

		var pixbuf = new Gdk.Pixbuf.from_file (screenshot_path);
		view.set_pixbuf (pixbuf);
	}

	private bool on_shutdown () {
		stop ();

		return true;
	}

	private string get_unsupported_system_message () {
		var platform_name = platform.get_name ();
		if (platform_name != null)
			return _("The system “%s” isn’t supported yet, but full support is planned.").printf (platform_name);

		return _("The system isn’t supported yet, but full support is planned.");
	}

	public Retro.Core get_core () {
		return core;
	}
}
