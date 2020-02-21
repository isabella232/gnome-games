// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunner : Object, Runner {
	private const int MAX_AUTOSAVES = 5;

	public bool can_fullscreen {
		get { return true; }
	}

	public bool can_resume {
		get { return game_savestates.length != 0; }
	}

	public bool supports_savestates {
		get { return core.get_can_access_state (); }
	}

	public bool is_integrated {
		get { return true; }
	}

	private MediaSet _media_set;
	public MediaSet? media_set {
		get { return _media_set; }
	}

	public InputCapabilities input_capabilities { get; set; }

	private Retro.Core core;
	private Retro.CoreView view;
	private RetroInputManager input_manager;
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
	private Settings settings;
	private Game game;

	private Savestate[] game_savestates;
	private Savestate latest_savestate;
	private Savestate tmp_live_savestate;
	private Savestate previewed_savestate;

	private Gdk.Pixbuf current_state_pixbuf;

	private bool _running;
	private bool running {
		get { return _running; }
		set {
			_running = value;
			view.sensitive = running;
		}
	}

	private bool is_initialized;
	private bool is_ready;
	private bool is_error;

	private RetroRunner (Game game) {
		this.game = game;

		_media_set = game.get_media_set ();
		if (media_set == null && game.uri != null) {
			var media = new Media ();
			media.add_uri (game.uri);

			_media_set = new MediaSet ();
			_media_set.add_media (media);

			_media_set.notify["selected-media-number"].connect (on_media_number_changed);
		}
	}

	public RetroRunner.from_source (Game game, RetroCoreSource source) {
		this (game);

		core_source = source;
	}

	public RetroRunner.from_descriptor (Game game, Retro.CoreDescriptor descriptor) {
		this (game);

		core_descriptor = descriptor;
	}

	construct {
		is_initialized = false;
		is_ready = false;

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
		try {
			init_phase_one ();
		// TODO: Check for the two RetroErrors using RetroCoreManager
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
		catch (Error e) {
			debug (e.message);
			error_message = e.message;

			return false;
		}

		// Nothing went wrong
		error_message = "";
		return true;
	}

	private string get_core_id () throws Error {
		if (core_descriptor != null)
			return core_descriptor.get_id ();
		else
			return core_source.get_core_id ();
	}

	private void init_phase_one () throws Error {
		// Step 1) Load the game's savestates ----------------------------------
		game_savestates = Savestate.get_game_savestates (game.uid, game.platform, get_core_id ());
		if (game_savestates.length != 0)
			latest_savestate = game_savestates[0];

		// Step 2) Init the CoreView -------------------------------------------
		// This is done here such that get_display() won't return null
		view = new Retro.CoreView ();
		settings.changed["video-filter"].connect (on_video_filter_changed);
		on_video_filter_changed ();

		// Step 3) Instantiate the core
		// This is needed to check if the core supports savestates
		if (latest_savestate != null)
			tmp_live_savestate = latest_savestate.clone_in_tmp ();
		else
			tmp_live_savestate = Savestate.create_empty_in_tmp (game.platform, get_core_id ());
		instantiate_core (tmp_live_savestate.get_save_directory_path ());

		// Step 4) Preview the latest savestate --------------------------------
		if (latest_savestate != null)
			preview_savestate (latest_savestate);
	}

	public Gtk.Widget get_display () {
		return view;
	}

	public virtual HeaderBarWidget? get_extra_widget () {
		return null;
	}

	public void capture_current_state_pixbuf () {
		current_state_pixbuf = view.get_pixbuf ();
	}

	public void preview_current_state () {
		view.set_pixbuf (current_state_pixbuf);
	}

	public void preview_savestate (Savestate savestate) {
		previewed_savestate = savestate;

		var screenshot_path = savestate.get_screenshot_path ();
		Gdk.Pixbuf pixbuf = null;

		// Treat errors locally because loading the savestate screenshot is not
		// a critical operation
		try {
			pixbuf = new Gdk.Pixbuf.from_file (screenshot_path);

			var aspect_ratio = savestate.screenshot_aspect_ratio;

			if (aspect_ratio != 0)
				Retro.pixbuf_set_aspect_ratio (pixbuf, (float) aspect_ratio);
		}
		catch (Error e) {
			warning ("Couldn't load %s: %s", screenshot_path, e.message);
		}

		view.set_pixbuf (pixbuf);
	}

	public void load_previewed_savestate () throws Error {
		tmp_live_savestate = previewed_savestate.clone_in_tmp ();
		core.save_directory = tmp_live_savestate.get_save_directory_path ();
		load_save_ram (previewed_savestate.get_save_ram_path ());
		core.load_state (previewed_savestate.get_snapshot_path ());

		if (previewed_savestate.has_media_data ())
			media_set.selected_media_number = previewed_savestate.get_media_data ();

		load_savestate_metadata (previewed_savestate);

		is_ready = true;
	}

	public Savestate[] get_savestates () {
		if (game_savestates == null)
			critical ("RetroRunner hasn't loaded snapshots. Call try_init_phase_one()");

		return game_savestates;
	}

	public void start () throws Error {
		reset_metadata (latest_savestate);

		if (!is_initialized) {
			if (latest_savestate != null)
				tmp_live_savestate = latest_savestate.clone_in_tmp ();
			else
				tmp_live_savestate = Savestate.create_empty_in_tmp (game.platform, get_core_id ());

			instantiate_core (tmp_live_savestate.get_save_directory_path ());
		}

		if (!is_ready) {
			if (latest_savestate != null)
				load_save_ram (latest_savestate.get_save_ram_path ());

			is_ready = true;
		}

		core.run ();

		running = true;
	}

	public void restart () {
		current_state_pixbuf = view.get_pixbuf ();
		try_create_savestate (true);
		core.reset ();
	}

	public void resume () {
		if (!is_initialized)
			return;

		if (!is_ready) {
			critical ("RetroRunner.resume() cannot be called if the game isn't playing");
			return;
		}

		// Unpause an already running game
		core.run ();
		running = true;
	}

	// instantiate_core is used to setup the core, which needs to have a savestate
	// in /tmp created and ready
	private void instantiate_core (string core_save_directory_path) throws Error {
		prepare_core (core_save_directory_path);

		input_manager = new RetroInputManager (core, view);
		// Keep the internal values of input_mode in sync between RetroRunner and RetroInputManager
		input_mode = get_available_input_modes ()[0];

		core.shutdown.connect (stop);
		core.crashed.connect ((core, error) => {
			is_error = true;
			crash (error);
		});

		running = false;

		is_initialized = true;
	}

	private void deinit () {
		if (!is_initialized)
			return;

		settings.changed["video-filter"].disconnect (on_video_filter_changed);

		core = null;

		if (view != null) {
			view.set_core (null);
			view = null;
		}

		input_manager = null;

		_running = false;
		is_initialized = false;
		is_ready = false;
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
			try {
				var options = new RetroOptions (options_path);
				options.apply (core);
			} catch (Error e) {
				critical (e.message);
			}

		var platforms_dir = Application.get_platforms_dir ();
		var platform_id = game.platform.get_id ();
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

		if (medias_uris.length > 0)
			core.set_current_media (media_set.selected_media_number);
	}

	public void pause () {
		if (!is_initialized)
			return;

		if (!running)
			return;

		if (!is_error) {
			current_state_pixbuf = view.get_pixbuf ();
			core.stop ();
		}

		//FIXME:
		// In the future here there will be code which updates the currently
		// used temporary savestate

		running = false;
	}

	public void stop () {
		if (!is_initialized)
			return;

		pause ();
		deinit ();
		stopped ();
	}

	public InputMode[] get_available_input_modes () {
		if (input_capabilities == null)
			return { InputMode.GAMEPAD };

		InputMode[] modes = {};

		if (input_capabilities.get_allow_keyboard_mode ())
			modes += InputMode.KEYBOARD;

		if (input_capabilities.get_allow_gamepad_mode ())
			modes += InputMode.GAMEPAD;

		return modes;
	}

	public virtual bool key_press_event (uint keyval, Gdk.ModifierType state) {
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
		var uid = game.uid.get_uid ();
		var core_id = get_core_id ();
		var core_id_prefix = core_id.replace (".libretro", "");

		return Path.build_filename (savestates_dir_path, uid + "-" + core_id_prefix);
	}

	// Returns the created Savestate or null if the Savestate couldn't be created
	// Currently the callers are the DisplayView and the SavestatesList
	// In the future we might want to throw Errors from here in case there is
	// something that can be done, but right now there's nothing we can do if
	// savestate creation fails except warn the user of unsaved progress via the
	// QuitDialog in the DisplayView
	public Savestate? try_create_savestate (bool is_automatic) {
		if (!core.get_can_access_state ()) // Check if the core can support savestates
			return null;

		if (!is_automatic)
			new_savestate_created ();

		try {
			return create_savestate (is_automatic);
		}
		catch (Error e) {
			critical ("Failed to create snapshot: %s", e.message);

			return null;
		}
	}

	private Savestate create_savestate (bool is_automatic) throws Error {
		// Make room for the new automatic savestate
		if (is_automatic)
			trim_autosaves ();

		// Populate the savestate in tmp with data from the current state of the game
		store_save_ram_in_tmp ();

		if (media_set.get_size () > 1)
			tmp_live_savestate.set_media_data (media_set);

		core.save_state (tmp_live_savestate.get_snapshot_path ());
		save_screenshot_in_tmp ();

		// Populate the metadata file
		tmp_live_savestate.is_automatic = is_automatic;

		if (is_automatic)
			tmp_live_savestate.name = null;
		else
			tmp_live_savestate.name = create_new_savestate_name ();

		tmp_live_savestate.creation_date = new DateTime.now ();
		tmp_live_savestate.screenshot_aspect_ratio = Retro.pixbuf_get_aspect_ratio (current_state_pixbuf);

		save_savestate_metadata (tmp_live_savestate);

		// Save the tmp_live_savestate into the game savestates directory
		var game_savestates_dir_path = get_game_savestates_dir_path ();
		var savestate = tmp_live_savestate.save_in (game_savestates_dir_path);

		// Update the game_savestates array
		// Insert the new savestate at the beginning of the array since it's the latest savestate
		Savestate[] new_game_savestates = {};

		new_game_savestates += savestate;
		foreach (var existing_savestate in game_savestates)
			new_game_savestates += existing_savestate;

		game_savestates = new_game_savestates;

		return savestate;
	}

	public void delete_savestate (Savestate savestate) {
		Savestate[] new_game_savestates = {};

		foreach (var existing_savestate in game_savestates) {
			if (savestate != existing_savestate)
				new_game_savestates += existing_savestate;
		}

		game_savestates = new_game_savestates;
		savestate.delete_from_disk ();
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
		if (core.get_memory_size (Retro.MemoryType.SAVE_RAM) == 0)
			return;

		core.save_memory (Retro.MemoryType.SAVE_RAM,
		                  tmp_live_savestate.get_save_ram_path ());
	}

	private void load_save_ram (string save_ram_path) throws Error {
		if (!FileUtils.test (save_ram_path, FileTest.EXISTS))
			return;

		if (core.get_memory_size (Retro.MemoryType.SAVE_RAM) == 0)
			return;

		core.load_memory (Retro.MemoryType.SAVE_RAM, save_ram_path);
	}

	private void save_screenshot_in_tmp () throws Error {
		var pixbuf = current_state_pixbuf;
		if (pixbuf == null)
			return;

		var screenshot_path = tmp_live_savestate.get_screenshot_path ();

		var now = new GLib.DateTime.now_local ();
		var creation_time = now.to_string ();
		var game_title = game.name;
		var platform = game.platform;
		var platform_name = platform.get_name ();
		var platform_id = platform.get_id ();
		if (platform_name == null) {
			critical ("Unknown name for platform %s", platform_id);
			platform_name = _("Unknown platform");
		}


		// See http://www.libpng.org/pub/png/spec/iso/index-object.html#11textinfo
		// for description of used keys. "Game Title" and "Platform" are
		// non-standard fields as allowed by PNG specification.
		pixbuf.save (screenshot_path, "png",
		             "tEXt::Software", "GNOME Games",
		             "tEXt::Title", @"Screenshot of $game_title on $platform_name",
		             "tEXt::Creation Time", creation_time.to_string (),
		             "tEXt::Game Title", game_title,
		             "tEXt::Platform", platform_name,
		             null);
	}

	private string get_unsupported_system_message () {
		var platform_name = game.platform.get_name ();
		if (platform_name != null)
			return _("The system “%s” isn’t supported yet, but full support is planned.").printf (platform_name);

		return _("The system isn’t supported yet, but full support is planned.");
	}

	public Retro.Core get_core () {
		return core;
	}

	private string create_new_savestate_name () throws Error {
		var list = new List<int>();
		var regex = new Regex (_("New snapshot %s").printf ("([1-9]\\d*)"));

		foreach (var savestate in game_savestates) {
			if (savestate.is_automatic)
				continue;

			MatchInfo match_info = null;

			if (regex.match (savestate.name, 0, out match_info)) {
				var number = match_info.fetch (1);
				list.prepend (int.parse (number));
			}
		}

		list.sort ((a, b) => a - b);

		// Find the next available name for a new manual savestate
		var next_number = 1;
		foreach (var number in list) {
			if (number == next_number)
				next_number++;
			else
				break;
		}

		return _("New snapshot %s").printf (next_number.to_string ());
	}

	// Decide if there are too many automatic savestates and delete the
	// last ones if so
	private void trim_autosaves () {
		// A new automatic savestate will be created right after this call,
		// so counter starts from 1
		int autosaves_counter = 1;

		foreach (var savestate in game_savestates) {
			if (savestate.is_automatic) {
				if (autosaves_counter < MAX_AUTOSAVES)
					autosaves_counter++;
				else
					savestate.delete_from_disk ();
			}
		}
	}

	protected virtual void save_savestate_metadata (Savestate savestate) throws Error {
		tmp_live_savestate.write_metadata ();
	}

	protected virtual void load_savestate_metadata (Savestate savestate) throws Error {
	}

	protected virtual void reset_metadata (Savestate? last_savestate) throws Error {
		if (last_savestate != null && last_savestate.has_media_data ())
			media_set.selected_media_number = last_savestate.get_media_data ();
	}
}
