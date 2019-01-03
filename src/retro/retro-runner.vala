// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunner : Object, Runner {
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
				if (!core.get_can_access_state ())
					return false;

				var snapshot_path = get_snapshot_path ();
				var file = File.new_for_path (snapshot_path);

				return file.query_exists ();
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

	private string save_directory_path;
	private string save_path;
	private string snapshot_path;
	private string screenshot_path;

	private Retro.CoreDescriptor core_descriptor;
	private RetroCoreSource core_source;
	private Platform platform;
	private Uid uid;
	private InputCapabilities input_capabilities;
	private Settings settings;
	private Title game_title;

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

	internal RetroRunner (RetroRunnerBuilder builder) {
		is_initialized = false;
		is_ready = false;
		should_save = false;

		core_descriptor = builder.core_descriptor;
		_media_set = builder.media_set;

		uid = builder.uid;
		core_source = builder.core_source;
		platform = builder.platform;
		input_capabilities = builder.input_capabilities;
		game_title = builder.title;

		_media_set.notify["selected-media-number"].connect (on_media_number_changed);
	}

	construct {
		settings = new Settings ("org.gnome.Games");
	}

	~RetroRunner () {
		pause ();
		deinit ();
	}

	public bool check_is_valid (out string error_message) throws Error {
		try {
			load_media_data ();
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

	public Gtk.Widget? get_extra_widget () {
		return null;
	}

	public void start () throws Error {
		load_media_data ();

		if (!is_initialized)
			init ();

		loop.stop ();

		if (!is_ready) {
			load_ram ();
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
			load_ram ();
			core.reset ();
			load_snapshot ();
			is_ready = true;
		}

		loop.start ();
		running = true;
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

		load_screenshot ();

		is_initialized = true;
	}

	private void deinit () {
		if (!is_initialized)
			return;

		settings.changed["video-filter"].disconnect (on_video_filter_changed);

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

		var platforms_dir = Application.get_platforms_dir ();
		var platform_id = platform.get_id ();
		core.system_directory = @"$platforms_dir/$platform_id/system";

		var save_directory = get_save_directory_path ();
		Application.try_make_dir (save_directory);
		core.save_directory = save_directory;

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
		running = false;


		try {
			save ();
		}
		catch (Error e) {
			warning (e.message);
		}
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

		if (input_capabilities.get_allow_keyboard_mode ())
			return { InputMode.GAMEPAD, InputMode.KEYBOARD };
		else
			return { InputMode.GAMEPAD };
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

		try {
			save_media_data ();
		}
		catch (Error e) {
			warning (e.message);
		}
	}

	private void save () throws Error {
		if (!should_save)
			return;

		save_ram ();

		if (media_set.get_size () > 1)
			save_media_data ();

		if (!core.get_can_access_state ())
			return;

		save_snapshot ();
		save_screenshot ();

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

	private string get_save_directory_path () throws Error {
		if (save_directory_path != null)
			return save_directory_path;

		var dir = Application.get_saves_dir ();
		var uid = uid.get_uid ();
		save_directory_path = @"$dir/$uid";

		return save_directory_path;
	}

	private string get_save_path () throws Error {
		if (save_path != null)
			return save_path;

		var dir = Application.get_saves_dir ();
		var uid = uid.get_uid ();
		save_path = @"$dir/$uid.save";

		return save_path;
	}

	private void save_ram () throws Error{
		var bytes = core.get_memory (Retro.MemoryType.SAVE_RAM);
		var save = bytes.get_data ();
		if (save.length == 0)
			return;

		var dir = Application.get_saves_dir ();
		Application.try_make_dir (dir);

		var save_path = get_save_path ();

		FileUtils.set_data (save_path, save);
	}

	private void load_ram () throws Error {
		var save_path = get_save_path ();

		if (!FileUtils.test (save_path, FileTest.EXISTS))
			return;

		uint8[] data = null;
		FileUtils.get_data (save_path, out data);

		var expected_size = core.get_memory_size (Retro.MemoryType.SAVE_RAM);
		if (data.length != expected_size)
			warning ("Unexpected RAM data size: got %lu, expected %lu\n", data.length, expected_size);

		var bytes = new Bytes.take (data);
		core.set_memory (Retro.MemoryType.SAVE_RAM, bytes);
	}

	private string get_snapshot_path () throws Error {
		if (snapshot_path != null)
			return snapshot_path;

		var dir = Application.get_snapshots_dir ();
		var uid = uid.get_uid ();
		snapshot_path = @"$dir/$uid.snapshot";

		return snapshot_path;
	}

	private void save_snapshot () throws Error {
		var bytes = core.get_state ();
		var buffer = bytes.get_data ();

		var dir = Application.get_snapshots_dir ();
		Application.try_make_dir (dir);

		var snapshot_path = get_snapshot_path ();

		FileUtils.set_data (snapshot_path, buffer);
	}

	private void load_snapshot () throws Error {
		if (!core.get_can_access_state ())
			return;

		var snapshot_path = get_snapshot_path ();

		if (!FileUtils.test (snapshot_path, FileTest.EXISTS))
			return;

		uint8[] data = null;
		FileUtils.get_data (snapshot_path, out data);

		var bytes = new Bytes.take (data);
		core.set_state (bytes);
	}

	private void save_media_data () throws Error {
		var dir = Application.get_medias_dir ();
		Application.try_make_dir (dir);

		var medias_path = get_medias_path ();

		string contents = media_set.selected_media_number.to_string ();

		FileUtils.set_contents (medias_path, contents, contents.length);
	}

	private void load_media_data () throws Error {
		var medias_path = get_medias_path ();

		if (!FileUtils.test (medias_path, FileTest.EXISTS))
			return;

		string contents;
		FileUtils.get_contents (medias_path, out contents);

		int disc_num = int.parse (contents);
		media_set.selected_media_number = disc_num;
	}

	private string get_medias_path () throws Error {
		var dir = Application.get_medias_dir ();
		var uid = uid.get_uid ();

		return @"$dir/$uid.media";
	}

	private string get_screenshot_path () throws Error {
		if (screenshot_path != null)
			return screenshot_path;

		var dir = Application.get_snapshots_dir ();
		var uid = uid.get_uid ();
		screenshot_path = @"$dir/$uid.png";

		return screenshot_path;
	}

	private void save_screenshot () throws Error {
		if (!core.get_can_access_state ())
			return;

		var pixbuf = view.get_pixbuf ();
		if (pixbuf == null)
			return;

		var screenshot_path = get_screenshot_path ();

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

		var screenshot_path = get_screenshot_path ();

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
}
