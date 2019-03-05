// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Application : Gtk.Application {
	const string HELP_URI = "https://wiki.gnome.org/Apps/Games/Documentation";

	private static bool? is_flatpak;

	private Database database;

	private PreferencesWindow preferences_window;
	private ApplicationWindow window;
	private bool game_list_loaded;

	private GameCollection game_collection;

	private Manette.Monitor manette_monitor;

	internal Application () {
		Object (application_id: Config.APPLICATION_ID,
		        flags: ApplicationFlags.HANDLES_OPEN);
	}

	construct {
		Environment.set_prgname (Config.APPLICATION_ID);
		Environment.set_application_name (_("Games"));
		Gtk.Window.set_default_icon_name (Config.APPLICATION_ID);
		Environment.set_variable ("PULSE_PROP_media.role", "game", true);
		Environment.set_variable ("PULSE_PROP_application.icon_name", Config.APPLICATION_ID, true);

		add_actions ();
		add_signal_handlers ();

		try_make_dir (get_data_dir ());

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
		SimpleAction preferences_action = new SimpleAction ("preferences", null);
		preferences_action.activate.connect (preferences);
		add_action (preferences_action);

		SimpleAction help_action = new SimpleAction ("help", null);
		help_action.activate.connect (help);
		add_action (help_action);

		SimpleAction about_action = new SimpleAction ("about", null);
		about_action.activate.connect (about);
		add_action (about_action);

		SimpleAction quit_action = new SimpleAction ("quit", null);
		quit_action.activate.connect (quit_application);
		add_action (quit_action);

		SimpleAction add_game_files_action = new SimpleAction ("add-game-files", null);
		add_game_files_action.activate.connect (add_game_files);
		add_action (add_game_files_action);
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

	public static string get_saves_dir () {
		var data_dir = get_data_dir ();

		return @"$data_dir/saves";
	}

	public static string get_snapshots_dir () {
		var data_dir = get_data_dir ();

		return @"$data_dir/snapshots";
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

	public static string get_covers_cache_dir (int size) {
		var covers_dir = get_covers_dir ();

		return @"$covers_dir/$size";
	}

	public static void try_make_dir (string path) {
		var file = File.new_for_path (path);
		try {
			if (!file.query_exists ())
				file.make_directory_with_parents ();
		}
		catch (Error e) {
			warning (@"$(e.message)\n");
		}
	}

	public static string get_medias_dir () {
		var data_dir = get_data_dir ();

		return @"$data_dir/medias";
	}

	public static bool is_running_in_flatpak () {
		if (is_flatpak != null)
			return is_flatpak;

		var file = File.new_for_path ("/.flatpak-info");

		is_flatpak = file.query_exists ();

		return is_flatpak;
	}

	public void add_game_files () {
		add_game_files_async.begin ();
	}

	public async void add_game_files_async () {
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
				yield add_cached_uri (uri);
			}

		chooser.close ();
	}

	protected override void open (File[] files, string hint) {
		open_async.begin (files, hint);
	}

	private async void open_async (File[] files, string hint) {
		if (window == null)
			activate ();

		if (files.length == 0)
			return;

		Uri[] uris = {};
		foreach (var file in files)
			uris += new Uri.from_file (file);

		var game = yield game_for_uris (uris);

		if (game != null)
			window.run_game (game);
		// else
			// TODO Display an error
	}

	protected override void activate () {
		Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

		var screen = Gdk.Screen.get_default ();
		var provider = load_css ("gtk-style.css");
		Gtk.StyleContext.add_provider_for_screen (screen, provider, 600);

		init_game_sources ();
		load_game_list.begin ();
		ListStore list_store = new ListStore (typeof (Game));
		game_collection.game_added.connect ((game) => {
			if (database != null)
				list_store.append (new DatabaseGame (database, game));
			else
				list_store.append (game);
		});

		if (window != null) {
			window.present_with_time (Gtk.get_current_event_time ());
			return;
		}

		window = new ApplicationWindow (this, list_store);
		window.destroy.connect (() => {
			quit_application ();
		});
		window.show ();

		GLib.Timeout.add (500, show_loading_notification);
	}

	private bool show_loading_notification () {
		if (!game_list_loaded)
			window.loading_notification = true;

		return false;
	}

	private void init_game_sources () {
		if (game_collection != null)
			return;

		TrackerUriSource tracker_uri_source = null;
		try {
			var connection = Tracker.Sparql.Connection.@get ();
			tracker_uri_source = new TrackerUriSource (connection);
		}
		catch (Error e) {
			debug (e.message);
		}

		game_collection = new GameCollection ();
		if (database != null)
			game_collection.add_source (database.get_uri_source ());

		if (tracker_uri_source != null)
			game_collection.add_source (tracker_uri_source);

		var mime_types = new GenericSet<string> (str_hash, str_equal);

		/* Register simple Libretro-based game types */
		foreach (var simple_type in RETRO_SIMPLE_TYPES) {
			assert (!mime_types.contains (simple_type.mime_type));

			if (simple_type.search_mime_type && tracker_uri_source != null) {
				mime_types.add (simple_type.mime_type);
				var query = new MimeTypeTrackerUriQuery (simple_type.mime_type);
				tracker_uri_source.add_query (query);
			}

			var game_uri_adapter = new RetroSimpleGameUriAdapter (simple_type);
			var factory = new GenericUriGameFactory (game_uri_adapter);
			factory.add_mime_type (simple_type.mime_type);

			game_collection.add_factory (factory);
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

				foreach (var uri_source in plugin.get_uri_sources ())
					game_collection.add_source (uri_source);

				foreach (var factory in plugin.get_uri_game_factories ())
					game_collection.add_factory (factory);
			}
			catch (Error e) {
				debug ("Error: %s", e.message);
			}
		}
	}

	private async Game? game_for_uris (Uri[] uris) {
		init_game_sources ();

		foreach (var uri in uris)
			yield add_cached_uri (uri);

		return yield game_collection.query_game_for_uri (uris[0]);
	}

	private async void add_cached_uri (Uri uri) {
		try {
			if (database != null)
					database.add_uri (uri);
		}
		catch (Error e) {
			debug (e.message);
		}

		yield game_collection.add_uri (uri);
	}

	internal async void load_game_list () {
		if (!yield game_collection.search_games ())
			return;

		game_list_loaded = true;
		if (window != null)
			window.loading_notification = false;
	}

	public void set_pause_loading (bool paused) {
		game_collection.paused = paused;

		load_game_list.begin ();
	}

	private void preferences () {
		if (preferences_window == null) {
			preferences_window = new PreferencesWindow ();
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
		if (window != null && !window.quit_game ())
			return;

		quit ();
	}

	private static Gtk.CssProvider load_css (string css) {
		var provider = new Gtk.CssProvider ();
		try {
			var file = File.new_for_uri ("resource:///org/gnome/Games/" + css);
			provider.load_from_file (file);
		} catch (GLib.Error e) {
			warning ("Loading CSS file “%s” failed: %s", css, e.message);
		}
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
}
