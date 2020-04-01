// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunner : Object, Runner {
	public signal void controllers_changed ();

	public bool can_fullscreen {
		get { return true; }
	}

	public bool can_resume {
		get {
			if (snapshot_manager == null)
				return false;

			return snapshot_manager.has_snapshots ();
		}
	}

	public bool supports_snapshots {
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
	private SnapshotManager snapshot_manager;

	private Snapshot previewed_snapshot;

	private string tmp_save_dir;

	private Gdk.Pixbuf current_state_pixbuf;

	private bool _running;
	private bool running {
		get { return _running; }
		set {
			_running = value;
			view.sensitive = running;
		}
	}

	private bool core_loaded;
	private bool is_error;

	public RetroRunner.from_source (Game game, RetroCoreSource source) {
		this.game = game;

		core_source = source;

		_media_set = game.media_set;
		if (media_set == null && game.uri != null) {
			var media = new Media ();
			media.add_uri (game.uri);

			_media_set = new MediaSet ();
			_media_set.add_media (media);
		}

		_media_set.notify["selected-media-number"].connect (on_media_number_changed);
	}

	public RetroRunner.from_descriptor (Game game, Retro.CoreDescriptor descriptor) {
		this.game = game;

		core_descriptor = descriptor;

		_media_set = new MediaSet ();
	}

	construct {
		settings = new Settings ("org.gnome.Games");
		view = new Retro.CoreView ();

		settings.changed["video-filter"].connect (on_video_filter_changed);
		on_video_filter_changed ();
	}

	private void on_video_filter_changed () {
		var filter_name = settings.get_string ("video-filter");
		var filter = Retro.VideoFilter.from_string (filter_name);
		view.set_filter (filter);
	}

	~RetroRunner () {
		deinit ();
	}

	public Gtk.Widget get_display () {
		return view;
	}

	public virtual HeaderBarWidget? get_extra_widget () {
		return null;
	}

	private string get_unsupported_system_message () {
		var platform_name = game.platform.get_name ();
		if (platform_name != null)
			return _("The system “%s” isn’t supported yet, but full support is planned.").printf (platform_name);

		return _("The system isn’t supported yet, but full support is planned.");
	}

	private string get_core_id () throws Error {
		if (core_descriptor != null)
			return core_descriptor.get_id ();
		else
			return core_source.get_core_id ();
	}

	private string create_tmp_save_dir () throws Error {
		return DirUtils.make_tmp ("games_save_dir_XXXXXX");
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

	private void prepare_core () throws Error {
		string module_path;
		if (core_descriptor != null) {
			var module_file = core_descriptor.get_module_file ();
			if (module_file == null)
				throw new RetroError.MODULE_NOT_FOUND ("No module found for “%s”.", core_descriptor.get_name ());

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

		core.save_directory = tmp_save_dir;

		core.log.connect (Retro.g_log);
		core.shutdown.connect (stop);
		core.crashed.connect ((core, error) => {
			is_error = true;
			crash (error);
		});

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

		input_manager = new RetroInputManager (core, view);
		input_manager.controllers_changed.connect (() => {
			controllers_changed ();
		});

		// Keep the internal values of input_mode in sync between RetroRunner and RetroInputManager
		input_mode = get_available_input_modes ()[0];

		core_loaded = true;
	}

	public void prepare () throws RunnerError {
		try {
			snapshot_manager = new SnapshotManager (game, get_core_id ());

			var snapshot = snapshot_manager.get_latest_snapshot ();

			tmp_save_dir = create_tmp_save_dir ();
			if (snapshot != null)
				snapshot.copy_save_dir_to (tmp_save_dir);

			prepare_core ();

			reset_with_snapshot (snapshot);

			if (snapshot != null)
				preview_snapshot (snapshot);
		}
		catch (RetroError.MODULE_NOT_FOUND e) {
			debug ("%s\n", e.message);
			throw new RunnerError.UNSUPPORTED_SYSTEM (get_unsupported_system_message ());
		}
		catch (RetroError.FIRMWARE_NOT_FOUND e) {
			debug ("%s\n", e.message);
			throw new RunnerError.UNSUPPORTED_SYSTEM (get_unsupported_system_message ());
		}
		catch (Error e) {
			throw new RunnerError.OTHER (e.message);
		}
	}

	public void start () throws Error {
		assert (core_loaded);

		resume ();
	}

	public void resume () {
		if (!core_loaded)
			return;

		// Unpause an already running game
		core.run ();
		running = true;
	}

	public void pause () {
		if (!core_loaded)
			return;

		if (!running)
			return;

		if (!is_error) {
			current_state_pixbuf = view.get_pixbuf ();
			core.stop ();
		}

		running = false;
	}

	public void stop () {
		if (!core_loaded)
			return;

		deinit ();
		stopped ();
	}

	private void deinit () {
		if (!core_loaded)
			return;

		settings.changed["video-filter"].disconnect (on_video_filter_changed);

		input_manager = null;

		if (!is_error && core.is_initiated)
			core.stop ();

		core = null;

		if (view != null) {
			view.set_core (null);
			view = null;
		}

		_running = false;
		core_loaded = false;
	}

	public Snapshot? try_create_snapshot (bool is_automatic) {
		if (!supports_snapshots)
			return null;

		if (!is_automatic)
			snapshot_created ();

		try {
			return snapshot_manager.create_snapshot (is_automatic, save_to_snapshot);
		}
		catch (Error e) {
			critical ("Failed to create snapshot: %s", e.message);

			return null;
		}
	}

	public void delete_snapshot (Snapshot snapshot) {
		snapshot_manager.delete_snapshot (snapshot);
	}

	public void preview_snapshot (Snapshot snapshot) {
		previewed_snapshot = snapshot;

		var screenshot_path = snapshot.get_screenshot_path ();
		Gdk.Pixbuf pixbuf = null;

		// Treat errors locally because loading the snapshot screenshot is not
		// a critical operation
		try {
			pixbuf = new Gdk.Pixbuf.from_file (screenshot_path);

			var aspect_ratio = snapshot.screenshot_aspect_ratio;

			if (aspect_ratio != 0)
				Retro.pixbuf_set_aspect_ratio (pixbuf, (float) aspect_ratio);
		}
		catch (Error e) {
			warning ("Couldn't load %s: %s", screenshot_path, e.message);
		}

		view.set_pixbuf (pixbuf);
	}

	public void preview_current_state () {
		view.set_pixbuf (current_state_pixbuf);
	}

	public void load_previewed_snapshot () throws Error {
		load_from_snapshot (previewed_snapshot);
	}

	public Snapshot[] get_snapshots () {
		if (snapshot_manager == null)
			return {};

		return snapshot_manager.get_snapshots ();
	}

	public InputMode[] get_available_input_modes () {
		if (input_capabilities == null)
			return { InputMode.GAMEPAD };

		InputMode[] modes = {};

		if (input_capabilities.get_allow_gamepad_mode ())
			modes += InputMode.GAMEPAD;

		if (input_capabilities.get_allow_keyboard_mode ())
			modes += InputMode.KEYBOARD;

		return modes;
	}

	public virtual bool key_press_event (uint keyval, Gdk.ModifierType state) {
		return false;
	}

	public virtual bool gamepad_button_press_event (uint16 button) {
		return false;
	}

	private void on_media_number_changed () {
		if (!core_loaded)
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

	public Retro.Core get_core () {
		return core;
	}

	private void save_screenshot (string path) throws Error {
		var pixbuf = current_state_pixbuf;
		if (pixbuf == null)
			return;

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
		pixbuf.save (path, "png",
		             "tEXt::Software", "GNOME Games",
		             "tEXt::Title", @"Screenshot of $game_title on $platform_name",
		             "tEXt::Creation Time", creation_time.to_string (),
		             "tEXt::Game Title", game_title,
		             "tEXt::Platform", platform_name,
		             null);
	}

	private void load_save_ram (string save_ram_path) throws Error {
		if (!FileUtils.test (save_ram_path, FileTest.EXISTS))
			return;

		if (core.get_memory_size (Retro.MemoryType.SAVE_RAM) == 0)
			return;

		core.load_memory (Retro.MemoryType.SAVE_RAM, save_ram_path);
	}

	protected virtual void save_to_snapshot (Snapshot snapshot) throws Error {
		if (core.get_memory_size (Retro.MemoryType.SAVE_RAM) > 0)
			core.save_memory (Retro.MemoryType.SAVE_RAM,
			                  snapshot.get_save_ram_path ());

		var tmp_dir = File.new_for_path (tmp_save_dir);
		var dest_dir = File.new_for_path (snapshot.get_save_directory_path ());
		FileOperations.copy_contents (tmp_dir, dest_dir);

		if (media_set.get_size () > 1)
			snapshot.set_media_data (media_set);

		core.save_state (snapshot.get_snapshot_path ());
		save_screenshot (snapshot.get_screenshot_path ());
		snapshot.screenshot_aspect_ratio = Retro.pixbuf_get_aspect_ratio (current_state_pixbuf);
	}

	protected virtual void load_from_snapshot (Snapshot snapshot) throws Error {
		tmp_save_dir = create_tmp_save_dir ();
		snapshot.copy_save_dir_to (tmp_save_dir);
		core.save_directory = tmp_save_dir;

		load_save_ram (snapshot.get_save_ram_path ());
		core.load_state (snapshot.get_snapshot_path ());

		if (snapshot.has_media_data ())
			media_set.selected_media_number = snapshot.get_media_data ();
	}

	protected virtual void reset_with_snapshot (Snapshot? last_snapshot) throws Error {
		if (last_snapshot == null)
			return;

		load_save_ram (last_snapshot.get_save_ram_path ());

		if (last_snapshot.has_media_data ())
			media_set.selected_media_number = last_snapshot.get_media_data ();
	}
}
