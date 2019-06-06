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
		get { return game_savestates.length != 0; }
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
	private Savestate tmp_live_savestate;

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

	// init_phase_one attempts to init everything that can be init-ed right away
	// It is called by the DisplayView to check if a runner can be used
	// This method must be called before other methods/properties
	public bool try_init_phase_one (out string error_message) {
		// Step 1) Check for the two RetroErrors -------------------------------
		// FIXME: Write this properly using RetroCoreManager
		/*
		try {
			media_set.selected_media_number = 0;
			//init ();
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
		*/

		// Step 2) Load the game's savestates ----------------------------------
		try {
			core_source.get_module_path (); // FIXME: Hack needed to get core_id
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
		}
		catch (Error e) {
			error_message = e.message;
			return false;
		}

		// Step 3) Init the CoreView -------------------------------------------
		// This is done here such that get_display() won't return null
		view = new Retro.CoreView ();
		settings.changed["video-filter"].connect (on_video_filter_changed);
		on_video_filter_changed ();

		// Step 4) Display the screenshot of the latest_savestate --------------
		// FIXME: This does not work currently, but perhaps we can fix it
		// somehow in retro-gtk ? We should be able to render a picture on the
		// screen without having to boot the core itself
		try {
			load_screenshot ();
		}
		catch (Error e) {
			error_message = e.message;
			return false;
		}

		// Nothing went wrong
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

		if (!is_initialized) {
			if (latest_savestate != null)
				tmp_live_savestate = latest_savestate.clone_in_tmp ();
			else
				tmp_live_savestate = Savestate.create_empty_in_tmp ();

			init_phase_two (tmp_live_savestate.get_save_directory_path ());
		}

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
		if (is_ready) {
			// In this case, the effect is to simply "unpause" an already running game
			loop.start ();
		}
		else {
			// In this case, the effect is to load the data from a savestate and
			// run the game
			if (!is_initialized) {
				tmp_live_savestate = latest_savestate.clone_in_tmp ();
				init_phase_two (tmp_live_savestate.get_save_directory_path ());
			}

			loop.stop ();

			// TODO: This will become "load_data_from_arbitrary_savestate ()"
			load_data_from_latest_savestate ();

			loop.start ();
		}

		// In both cases the game is now running
		running = true;
	}

	// init_phase_two is used to setup the core, which needs to have the savestate
	// in /tmp created and ready
	private void init_phase_two (string core_save_directory_path) throws Error {
		prepare_core (core_save_directory_path);

		var present_analog_sticks = input_capabilities == null || input_capabilities.get_allow_analog_gamepads ();
		input_manager = new RetroInputManager (core, view, present_analog_sticks);
		// Keep the internal values of input_mode in sync between RetroRunner and RetroInputManager
		_input_mode = input_manager.input_mode;

		core.shutdown.connect (on_shutdown);

		core.run (); // Needed to finish preparing some cores.

		loop = new Retro.MainLoop (core);
		running = false;

		is_initialized = true;
	}

	private void load_data_from_latest_savestate () throws Error {
		// TODO: This method assumes that there exists at least a savestate
		// [Yeti]: Perhaps we should bug-proof this using an Assert ?
		load_save_ram (latest_savestate.get_save_ram_path ());
		core.reset ();
		core.set_state (latest_savestate.get_snapshot_data ());

		if (latest_savestate.has_media_data ())
			media_set.selected_media_number = latest_savestate.get_media_data ();

		is_ready = true;
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

	private void prepare_core (string save_directory_path) throws Error {
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

		core.save_directory = save_directory_path;

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
		if (!core.get_can_access_state ()) // Check if the core can support savestates
			return;

		if (!should_save)
			return;

		store_save_ram_in_tmp ();
		// TODO: Also save the media data in tmp_savestate
		tmp_live_savestate.set_snapshot_data (core.get_state ());
		save_screenshot_in_tmp ();

		// Save the tmp_live_savestate into the game savestates directory
		var game_savestates_dir_path = get_game_savestates_dir_path ();
		tmp_live_savestate.save_in (game_savestates_dir_path);
		should_save = false;

		/*
		store_save_ram (new_savestate_dir);

		if (media_set.get_size () > 1)
			save_media_data (new_savestate_dir);
		*/
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

	private void store_save_ram_in_tmp () throws Error {
		var bytes = core.get_memory (Retro.MemoryType.SAVE_RAM);
		var save = bytes.get_data ();
		if (save.length == 0)
			return;

		tmp_live_savestate.set_save_ram_data (save);
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

	private void save_screenshot_in_tmp () throws Error {
		var pixbuf = view.get_pixbuf ();
		if (pixbuf == null)
			return;

		var screenshot_path = tmp_live_savestate.get_screenshot_path ();

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

	// Display the screenshot of the latest savestate
	private void load_screenshot () throws Error {
		if (game_savestates.length == 0)
			return;

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

