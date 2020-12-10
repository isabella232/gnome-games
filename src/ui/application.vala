// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Application : Gtk.Application {
	const string HELP_URI = "https://wiki.gnome.org/Apps/Games/Documentation";
	const string TEST_QUERY = "SELECT nie:url(?f) WHERE { ?f fts:match 'test query to check tracker' }";

	private static bool? is_flatpak;

	private Database database;

	private PreferencesWindow preferences_window;
	private ApplicationWindow window;
	private bool game_list_loaded;

	private GameCollection game_collection;
	private GameModel game_model;
	private CoverLoader cover_loader;

	private CollectionManager collection_manager;
	private CollectionModel collection_model;

	private Manette.Monitor manette_monitor;

	private bool tracker_failed;
	private bool initialized;

	private const ActionEntry[] action_entries = {
		{ "preferences",    preferences      },
		{ "help",           help             },
		{ "about",          about            },
		{ "quit",           quit_application },
		{ "add-game-files", add_game_files   },
	};

	private const OptionEntry[] option_entries = {
		{ "search", 0, 0, OptionArg.STRING_ARRAY,   null, N_("Search term")       },
		{ "uid",    0, 0, OptionArg.STRING,         null, N_("Run a game by uid") },
		{ "",       0, 0, OptionArg.FILENAME_ARRAY },
		{ null },
	};

	internal Application () {
		Object (application_id: Config.APPLICATION_ID,
		        flags: ApplicationFlags.HANDLES_OPEN | ApplicationFlags.HANDLES_COMMAND_LINE);
	}

	construct {
		Environment.set_prgname (Config.APPLICATION_ID);
		Environment.set_application_name (_("Games"));
		Gtk.Window.set_default_icon_name (Config.APPLICATION_ID);
		Environment.set_variable ("PULSE_PROP_media.role", "game", true);
		Environment.set_variable ("PULSE_PROP_application.icon_name", Config.APPLICATION_ID, true);

		add_main_option_entries (option_entries);
		add_actions ();
		add_signal_handlers ();

		make_data_dir ();

		var database_path = get_database_path ();
		try {
			database = new Database (database_path);
		}
		catch (Error e) {
			debug (e.message);
		}

		manette_monitor = new Manette.Monitor ();
		var manette_iterator = manette_monitor.iterate ();
		Manette.Device manette_device = null;
		while (manette_iterator.next (out manette_device))
			on_device_connected (manette_device);
		manette_monitor.device_connected.connect (on_device_connected);
	}

	private void add_actions () {
		add_action_entries (action_entries, this);
	}

	private void add_signal_handlers () {
		var interrupt_source = new Unix.SignalSource (ProcessSignal.INT);
		interrupt_source.set_callback (() => {
			quit_application ();

			return Source.CONTINUE;
		});
		interrupt_source.attach (MainContext.@default ());
	}

	public static string get_data_dir () {
		var data_dir = Environment.get_user_data_dir ();

		return @"$data_dir/gnome-games";
	}

	public static string get_database_path () {
		var data_dir = get_data_dir ();

		return @"$data_dir/database.sqlite3";
	}

	public static string get_cache_dir () {
		var cache_dir = Environment.get_user_cache_dir ();

		return @"$cache_dir/gnome-games";
	}

	public static string get_config_dir () {
		var config_dir = Environment.get_user_config_dir ();

		return @"$config_dir/gnome-games";
	}

	public static string get_platforms_dir () {
		var config_dir = get_config_dir ();

		return @"$config_dir/platforms";
	}

	public static string get_covers_dir () {
		var cache_dir = get_cache_dir ();

		return @"$cache_dir/covers";
	}

	public static string get_image_cache_dir (string dir_name, int size, int scale_factor) {
		var cache_dir = get_cache_dir ();

		return @"$cache_dir/$dir_name/$size@$(scale_factor)x";
	}

	private void make_data_dir () {
		var data_dir = File.new_for_path (get_data_dir ());
		try {
			if (data_dir.query_exists ())
				return;

			data_dir.make_directory_with_parents ();
			Migrator.bump_to_latest_version ();
		}
		catch (Error e) {
			critical ("Couldn't create data dir: %s", e.message);
		}
	}

	public static void try_make_dir (string path) {
		var file = File.new_for_path (path);
		try {
			if (!file.query_exists ())
				file.make_directory_with_parents ();
		}
		catch (Error e) {
			critical ("Couldn't create dir '%s': %s", path, e.message);
		}
	}

	public static bool is_running_in_flatpak () {
		if (is_flatpak != null)
			return is_flatpak;

		var file = File.new_for_path ("/.flatpak-info");

		is_flatpak = file.query_exists ();

		return is_flatpak;
	}

	public void add_game_files () {
		var chooser = new Gtk.FileChooserDialog (
			_("Select game files"), window, Gtk.FileChooserAction.OPEN,
			_("_Cancel"), Gtk.ResponseType.CANCEL,
			_("_Add"), Gtk.ResponseType.ACCEPT);


		chooser.select_multiple = true;

		var filter = new Gtk.FileFilter ();
		chooser.filter = filter;
		foreach (var mime_type in game_collection.get_accepted_mime_types ())
			filter.add_mime_type (mime_type);

		if (chooser.run () == Gtk.ResponseType.ACCEPT)
			foreach (unowned string uri_string in chooser.get_uris ()) {
				var uri = new Uri (uri_string);
				add_cached_uri (uri);
			}

		chooser.close ();
	}

	protected override void open (File[] files, string hint) {
		activate ();

		if (files.length == 0)
			return;

		Uri[] uris = {};
		foreach (var file in files)
			uris += new Uri.from_file (file);

		// FIXME: This is done because files[0] gets freed after yield
		var file = files[0];
		var game = game_for_uris (uris);

		if (game == null) {
			string filename;
			try {
				var fileinfo = file.query_info (FileAttribute.STANDARD_DISPLAY_NAME,
				                                FileQueryInfoFlags.NONE,
				                                null);
				filename = fileinfo.get_display_name ();
			} catch (Error e) {
				critical ("Couldn't retrieve filename: %s", e.message);
				filename = file.get_basename ();
			}

			var error_msg = _("An unexpected error occurred while trying to run %s").printf (filename);
			window.show_error (error_msg);
			return;
		}

		window.run_game.begin (game);
	}

	protected override void startup () {
		base.startup ();

		Hdy.init ();

		var screen = Gdk.Screen.get_default ();
		var provider = load_css ("gtk-style.css");
		Gtk.StyleContext.add_provider_for_screen (screen, provider, 600);

		Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

		var icon_theme = Gtk.IconTheme.get_default ();
		icon_theme.add_resource_path ("/org/gnome/Games/icons/");
		icon_theme.add_resource_path ("/org/gnome/Games/gesture");
	}

	private async void run_by_uid (string uid) {
		var game = yield game_collection.query_game_for_uid (uid);

		if (game == null) {
			window.show_error (_("Cannot find game with UID “%s”.").printf (uid));

			return;
		}

		window.run_game.begin (game);
	}

	protected override int command_line (ApplicationCommandLine command_line) {
		var options = command_line.get_options_dict ();

		activate ();

		if ("uid" in options) {
			var uid = options.lookup_value ("uid", VariantType.STRING);
			if (uid != null)
				run_by_uid.begin (uid.get_string ());

			return 0;
		}

		if ("search" in options) {
			var terms_variant = options.lookup_value ("search", VariantType.STRING_ARRAY);
			if (terms_variant != null) {
				var terms = terms_variant.get_strv ();
				window.run_search (string.joinv (" ", terms));
			}

			return 0;
		}

		var files_variant = options.lookup_value ("", VariantType.BYTESTRING_ARRAY);
		if (files_variant != null) {
			var filenames = files_variant.get_bytestring_array ();
			File[] files = {};

			foreach (var filename in filenames)
				files += command_line.create_file_for_arg (filename);

			open (files, "");
		}

		return 0;
	}

	protected override void activate () {
		if (!initialized) {
			init_game_sources ();

			game_model = new GameModel ();
			game_collection.game_added.connect (game_model.add_game);
			game_collection.game_replaced.connect (game_model.replace_game);
			game_collection.game_removed.connect (game_model.remove_game);

			collection_model = new CollectionModel ();
			collection_manager = new CollectionManager (database);
			collection_manager.collection_added.connect (collection_model.add_collection);
			collection_manager.collection_removed.connect (collection_model.remove_collection);

			load_game_list.begin ();

			cover_loader = new CoverLoader ();

			initialized = true;
		}

		if (window != null) {
			window.present_with_time (Gtk.get_current_event_time ());
			return;
		}

		window = new ApplicationWindow (this, game_model, collection_model);
		window.destroy.connect (() => {
			quit_application ();
		});
		window.show ();

		if (tracker_failed) {
			string error_msg = _("Couldn't find Tracker, automatic game discovery may not work.");
			window.show_error (error_msg);
		}

		GLib.Timeout.add (500, show_loading_notification);
	}

	private bool show_loading_notification () {
		if (!game_list_loaded && !game_collection.paused)
			window.loading_notification = true;

		return false;
	}

	private void init_game_sources () {
		if (game_collection != null)
			return;

		// Re-organize data_dir layout if necessary
		// This operation has to be executed _after_ the PlatformsRegister has
		// been populated and therefore this call is placed here
		Migrator.apply_migration_if_necessary (database);
		database.prepare_statements ();

		TrackerUriSource tracker_uri_source = null;
		try {
			var connection = Tracker.Sparql.Connection.@get ();
			connection.query (TEST_QUERY);
			tracker_uri_source = new TrackerUriSource (connection);
		}
		catch (Error e) {
			tracker_failed = true;
			critical ("Couldn't find Tracker: %s", e.message);
		}

		game_collection = new GameCollection (database);

		if (tracker_uri_source != null)
			game_collection.add_source (tracker_uri_source);

		var mime_types = new GenericSet<string> (str_hash, str_equal);
		var platform_register = PlatformRegister.get_register ();

		/* Register simple Libretro-based game types */
		foreach (var simple_type in RETRO_SIMPLE_TYPES) {
			assert (!mime_types.contains (simple_type.mime_type));

			if (simple_type.search_mime_type && tracker_uri_source != null) {
				mime_types.add (simple_type.mime_type);
				var query = new MimeTypeTrackerUriQuery (simple_type.mime_type);
				tracker_uri_source.add_query (query);
			}

			var platform_name = simple_type.get_platform_name ();
			var platform = new RetroPlatform (simple_type.platform, platform_name, { simple_type.mime_type }, simple_type.prefix);
			platform_register.add_platform (platform);

			var game_uri_adapter = new RetroSimpleGameUriAdapter (simple_type, platform);
			var factory = new GenericUriGameFactory (game_uri_adapter);
			factory.add_mime_type (simple_type.mime_type);

			game_collection.add_factory (factory);

			var runner_factory = new RetroRunnerFactory (platform);

			game_collection.add_runner_factory (runner_factory);
		}

		/* Register game types from the plugins */
		var register = PluginRegister.get_register ();
		foreach (var plugin_registrar in register) {
			try {
				var plugin = plugin_registrar.get_plugin ();

				if (tracker_uri_source != null)
					foreach (var mime_type in plugin.get_mime_types ()) {
						if (mime_types.contains (mime_type))
							continue;

						mime_types.add (mime_type);
						var query = new MimeTypeTrackerUriQuery (mime_type);
						tracker_uri_source.add_query (query);
					}

				foreach (var platform in plugin.get_platforms ())
					platform_register.add_platform (platform);

				foreach (var uri_source in plugin.get_uri_sources ())
					game_collection.add_source (uri_source);

				foreach (var factory in plugin.get_uri_game_factories ())
					game_collection.add_factory (factory);

				foreach (var factory in plugin.get_runner_factories ())
					game_collection.add_runner_factory (factory);
			}
			catch (Error e) {
				debug ("Error: %s", e.message);
			}
		}
	}

	private Game? game_for_uris (Uri[] uris) {
		init_game_sources ();

		foreach (var uri in uris)
			add_cached_uri (uri);

		return game_collection.query_game_for_uri (uris[0]);
	}

	private void add_cached_uri (Uri uri) {
		try {
			if (database != null)
					database.add_uri (uri);
		}
		catch (Error e) {
			debug (e.message);
		}

		game_collection.add_uri (uri);
	}

	internal async void load_game_list () {
		GLib.Timeout.add (500, show_loading_notification);

		yield game_collection.search_games ();

		if (game_collection.paused)
			return;

		game_list_loaded = true;
		if (window != null)
			window.loading_notification = false;
	}

	public void set_pause_loading (bool paused) {
		if (game_collection.paused == paused)
			return;

		game_collection.paused = paused;

		if (!paused)
			load_game_list.begin ();
	}

	private void preferences () {
		if (preferences_window == null) {
			preferences_window = new PreferencesWindow ();

			preferences_window.transient_for = window;
			preferences_window.modal = true;

			preferences_window.destroy.connect (() => {
				preferences_window = null;
			});
		}

		preferences_window.present_with_time (Gtk.get_current_event_time ());
	}

	private void help () {
		try {
			Gtk.show_uri_on_window (active_window, HELP_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	private void about () {
		Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
		dialog.destroy_with_parent = true;
		dialog.transient_for = window;
		dialog.modal = true;

		dialog.program_name = _("GNOME Games") + Config.NAME_SUFFIX;
		dialog.logo_icon_name = Config.APPLICATION_ID;
		dialog.comments = _("A video game player for GNOME");
		dialog.version = Config.VERSION;

		dialog.website = "https://wiki.gnome.org/Apps/Games";
		dialog.website_label = _("Learn more about GNOME Games");

		dialog.license_type = Gtk.License.GPL_3_0;

		dialog.authors = Credits.AUTHORS;
		dialog.artists = Credits.ARTISTS;
		dialog.documenters = Credits.DOCUMENTERS;
		dialog.translator_credits = _("translator-credits");

		dialog.response.connect ((response_id) => {
			if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT)
				dialog.hide_on_delete ();
		});

		dialog.present_with_time (Gtk.get_current_event_time ());
	}

	private void quit_application () {
		quit_application_internal.begin ();
	}

	private async void quit_application_internal () {
		if (window != null)
			return;

		if (window != null && !yield window.quit_game ())
			return;

		quit ();
	}

	private static Gtk.CssProvider load_css (string css) {
		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/org/gnome/Games/" + css);
		return provider;
	}

	private void on_gamepad_button_press_event (Manette.Device device, Manette.Event event) {
		window.gamepad_button_press_event (event);
	}

	private void on_gamepad_button_release_event (Manette.Event event) {
		window.gamepad_button_release_event (event);
	}

	private void on_gamepad_absolute_axis_event (Manette.Event event) {
		window.gamepad_absolute_axis_event (event);
	}

	private void on_device_connected (Manette.Device device) {
		device.button_press_event.connect (on_gamepad_button_press_event);
		device.button_release_event.connect (on_gamepad_button_release_event);
		device.absolute_axis_event.connect (on_gamepad_absolute_axis_event);
	}

	public static void import_from (string archive_path) throws ExtractionError {
		var data_dir = Application.get_data_dir ();
		string[] database = { Application.get_database_path () };

		FileOperations.extract_archive (archive_path, data_dir, database);
	}

	public static void export_to (string file_path) throws CompressionError {
		var data_dir = File.new_for_path (Application.get_data_dir ());
		string[] database = { Application.get_database_path () };

		FileOperations.compress_dir (file_path, data_dir, database);
	}

	internal GameCollection get_collection () {
		return game_collection;
	}

	internal CollectionManager get_collection_manager () {
		return collection_manager;
	}

	internal CoverLoader get_cover_loader () {
		return cover_loader;
	}

	internal new static Application get_default () {
		return GLib.Application.get_default () as Application;
	}
}

