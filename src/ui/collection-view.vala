// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-view.ui")]
private class Games.CollectionView : Gtk.Box, UiView {
	private const string CONTRIBUTE_URI = "https://wiki.gnome.org/Apps/Games/Contribute";

	public signal void game_activated (Game game);

	[GtkChild]
	private Hdy.Deck platforms_deck;
	[GtkChild]
	private Hdy.Deck collections_deck;
	[GtkChild]
	private Gtk.Stack header_bar_stack;
	[GtkChild]
	private Hdy.HeaderBar header_bar;
	[GtkChild]
	private Hdy.HeaderBar subview_header_bar;
	[GtkChild]
	private Hdy.HeaderBar selection_mode_header_bar;
	[GtkChild]
	private Hdy.ViewSwitcherTitle view_switcher_title;
	[GtkChild]
	private ErrorInfoBar error_info_bar;
	[GtkChild]
	private SearchBar search_bar;
	[GtkChild]
	private EmptyCollection empty_collection;
	[GtkChild]
	private EmptySearch empty_search;
	[GtkChild]
	private GamesPage games_page;
	[GtkChild]
	private PlatformsPage platforms_page;
	[GtkChild]
	private CollectionsPage collections_page;
	[GtkChild]
	private Hdy.HeaderBar collection_subpage_header_bar;
	[GtkChild]
	private SelectionActionBar selection_action_bar;
	[GtkChild]
	private Gtk.Stack empty_stack;
	[GtkChild]
	private Gtk.Stack viewstack;
	[GtkChild]
	private Hdy.ViewSwitcherBar view_switcher_bar;
	[GtkChild]
	private Hdy.SwipeGroup swipe_group;
	[GtkChild]
	private Hdy.SwipeGroup collections_swipe_group;
	[GtkChild]
	private UndoNotification undo_notification;
	[GtkChild]
	private Gtk.Entry collection_rename_entry;
	[GtkChild]
	private Gtk.Popover rename_popover;
	[GtkChild]
	private Gtk.Label collection_rename_error_label;
	[GtkChild]
	private Gtk.Label selection_mode_label;

	private bool _is_view_active;
	public bool is_view_active {
		get { return _is_view_active; }
		set {
			if (is_view_active == value)
				return;

			_is_view_active = value;

			if (!is_view_active)
				search_mode = false;

			konami_code.reset ();
		}
	}

	private bool _is_empty_collection;
	public bool is_empty_collection {
		get { return _is_empty_collection; }
		set {
			_is_empty_collection = value;
			if (_is_empty_collection)
				empty_stack.visible_child = empty_collection;
			else
				empty_stack.visible_child = viewstack;
		}
	}

	public string[] filtering_terms;
	public string filtering_text {
		 set {
			if (value == null)
				filtering_terms = null;
			else
				filtering_terms = value.split (" ");

			update_search_filters ();
		}
	}

	public Gtk.Window window { get; construct; }

	private GameModel _game_model;
	public GameModel game_model {
		get { return _game_model; }
		set {
			_game_model = value;

			games_page.game_model = game_model;
			platforms_page.game_model = game_model;

			is_empty_collection = game_model.get_n_items () == 0;
			game_model.items_changed.connect (() => {
				is_empty_collection = game_model.get_n_items () == 0;
			});
		}
	}

	public CollectionModel collection_model {
		get { return collections_page.collection_model; }
		set {
			collections_page.collection_model = value;
		}
	}

	public bool loading_notification { get; set; }
	public bool search_mode { get; set; }

	public bool is_folded { get; set; }
	public bool is_search_available { get; set; }
	public bool is_showing_bottom_bar { get; set; }
	public bool is_subview_open { get; set; }
	public bool is_selection_mode { get; set; }
	public bool is_selection_available { get; set; }
	public bool is_collection_rename_valid { get; set; }
	public bool show_game_actions { get; set; }
	public bool show_remove_action_button { get; set; }
	public bool is_add_available { get; set; }

	private CollectionManager collection_manager;
	private KonamiCode konami_code;
	private SimpleActionGroup action_group;
	private const ActionEntry[] action_entries = {
		{ "select-all",             select_all },
		{ "select-none",            select_none },
		{ "toggle-select",          toggle_select },
		{ "favorite-action",        favorite_action },
		{ "add-to-collection",      add_to_collection },
		{ "remove-collection",      remove_collection },
		{ "rename-collection",      rename_collection },
		{ "remove-from-collection", remove_from_collection }
	};

	construct {
		collection_manager = Application.get_default ().get_collection_manager ();
		collection_manager.collection_empty_changed.connect (() => {
			collections_page.invalidate_filter ();
		});

		undo_notification.undo.connect (collections_page.undo_remove_collection);
		undo_notification.closed.connect (collections_page.finalize_collection_removal);
		window.destroy.connect (collections_page.finalize_collection_removal);

		var icon_name = Config.APPLICATION_ID + "-symbolic";
		viewstack.child_set (games_page, "icon-name", icon_name);

		swipe_group.add_swipeable (platforms_page.get_leaflet ());
		collections_swipe_group.add_swipeable (collections_page.get_collections_deck ());

		konami_code = new KonamiCode (window);
		konami_code.code_performed.connect (on_konami_code_performed);

		action_group = new SimpleActionGroup ();
		action_group.add_action_entries (action_entries, this);
		window.insert_action_group ("view", action_group);

		update_add_game_availablity ();
		update_available_selection_actions ();
	}

	public void show_error (string error_message) {
		error_info_bar.show_error (error_message);
	}

	public bool on_button_pressed (Gdk.EventButton event) {
		return false;
	}

	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (window.get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		    (((window.get_direction () == Gtk.TextDirection.LTR) && keyval == Gdk.Key.Left) ||
		     ((window.get_direction () == Gtk.TextDirection.RTL) && keyval == Gdk.Key.Right)) &&
		     !is_selection_mode &&
		     (platforms_deck.navigate (Hdy.NavigationDirection.BACK) ||
		      collections_page.exit_subpage ())) {
			return true;
		}

		if ((keyval == Gdk.Key.f || keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK &&
		     !collections_page.is_collection_empty &&
		     !is_empty_collection) {
			if (!search_mode)
				search_mode = true;

			return true;
		}

		if ((keyval == Gdk.Key.question) &&
			(event.state & default_modifiers) == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK)) {

			var shortcuts_window = new ShortcutsWindow ();
			shortcuts_window.show_all();

			return true;
		}

		if (is_empty_collection)
			return false;

		if (is_selection_mode && keyval == Gdk.Key.Escape) {
			toggle_select ();
			return true;
		}

		if (is_empty_collection || (collections_page.is_subpage_open &&
		    collections_page.is_collection_empty))
			return false;

		return search_bar.handle_event (event);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		if (is_empty_collection)
			return false;

		switch (button) {
		case EventCode.BTN_TL:
			if (is_selection_mode || collections_page.is_subpage_open)
				return true;

			var views = viewstack.get_children ();
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.prev != null)
				viewstack.visible_child = current_view.prev.data;

			return true;
		case EventCode.BTN_TR:
			if (is_selection_mode || collections_page.is_subpage_open)
				return true;

			var views = viewstack.get_children ();
			unowned List<weak Gtk.Widget> current_view = views.find (viewstack.visible_child);

			assert (current_view != null);

			if (current_view.next != null)
				viewstack.visible_child = current_view.next.data;

			return true;
		default:
			if (viewstack.visible_child == platforms_page)
				return platforms_page.gamepad_button_press_event (event);
			else if (viewstack.visible_child == games_page)
				return games_page.gamepad_button_press_event (event);
			else
				return collections_page.gamepad_button_press_event (event);
		}
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platforms_page)
			return platforms_page.gamepad_button_release_event (event);
		else if (viewstack.visible_child == games_page)
			return games_page.gamepad_button_release_event (event);
		else
			return collections_page.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		if (!window.is_active)
			return false;

		if (!get_mapped ())
			return false;

		if (viewstack.visible_child == platforms_page)
			return platforms_page.gamepad_absolute_axis_event (event);
		else if (viewstack.visible_child == games_page)
			return games_page.gamepad_absolute_axis_event (event);
		else
			return collections_page.gamepad_absolute_axis_event (event);
	}

	private void on_konami_code_performed () {
		if (!is_view_active)
			return;

		try {
			Gtk.show_uri_on_window (window, CONTRIBUTE_URI, Gtk.get_current_event_time ());
		}
		catch (Error e) {
			critical (e.message);
		}
	}

	public void run_search (string query) {
		search_mode = true;
		search_bar.run_search (query);
	}

	private void select_none () {
		platforms_page.select_none ();
		games_page.select_none ();
		collections_page.select_none ();

		on_selected_items_changed ();
	}

	private void select_all () {
		if (viewstack.visible_child == platforms_page)
			platforms_page.select_all ();
		else if (viewstack.visible_child == games_page)
			games_page.select_all ();
		else
			collections_page.select_all ();

		on_selected_items_changed ();
	}

	private void toggle_select () {
		is_selection_mode = !is_selection_mode;
	}

	private Game[] get_currently_selected_games () {
		Game[] games;

		if (viewstack.visible_child == games_page)
			games = games_page.get_selected_games ();
		else if (viewstack.visible_child == platforms_page)
			games = platforms_page.get_selected_games ();
		else
			games = collections_page.get_selected_games ();

		return games;
	}

	private void add_to_collection () {
		// Finalize any pending removal of collection and dismiss undo notification if shown.
		collections_page.finalize_collection_removal ();

		var current_collection = !collections_page.is_subpage_open ? null :
		                         collections_page.current_collection;
		var dialog = new CollectionActionWindow (false, current_collection);
		dialog.collection_model = collection_model;
		dialog.transient_for = get_toplevel () as ApplicationWindow;
		dialog.modal = true;
		dialog.visible = true;

		dialog.confirmed.connect ((collections) => {
			var games = get_currently_selected_games ();
			foreach (var collection in collections)
				collection.add_games (games);

			select_none ();
		});
	}

	private void favorite_action () {
		collection_manager.toggle_favorite (get_currently_selected_games ());

		if (viewstack.visible_child == collections_page &&
		    collections_page.is_subpage_open &&
		    collections_page.current_collection.get_id () == "Favorites") {
			collections_page.update_is_collection_empty ();
			select_none ();
			toggle_select ();
			return;
		}

		on_selected_items_changed ();
	}

	public void remove_collection () {
		if (viewstack.visible_child != collections_page)
			return;

		if (collections_page.is_subpage_open && collections_page.is_showing_user_collection)
			collections_page.remove_current_user_collection ();
		else
			collections_page.remove_currently_selected_user_collections ();

		undo_notification.show_notification ();
		is_selection_mode = false;
	}

	public void rename_collection () {
		assert (collections_page.current_collection is UserCollection);
		collection_rename_entry.text = collections_page.collection_title;
		rename_popover.popup ();
		collection_rename_entry.grab_focus ();
	}

	private void remove_from_collection () {
		if (!collections_page.is_subpage_open || collections_page.current_collection == null)
			return;

		var games = get_currently_selected_games ();
		collections_page.current_collection.remove_games (games);
		collections_page.update_is_collection_empty ();
		select_none ();
	}

	private void update_available_selection_actions () {
		show_game_actions = viewstack.visible_child != collections_page ||
		                    collections_page.is_subpage_open;

		show_remove_action_button = viewstack.visible_child == collections_page &&
		                            !collections_page.is_subpage_open;
	}

	private void update_add_game_availablity () {
		is_add_available = viewstack.visible_child != collections_page;
	}

	private void update_search_filters () {
		if (viewstack.visible_child == games_page)
			games_page.set_filter (filtering_terms);
		else if (viewstack.visible_child == platforms_page)
			platforms_page.set_filter (filtering_terms);
		else
			collections_page.set_filter (filtering_terms);
	}

	[GtkCallback]
	private void on_collection_subpage_opened () {
		update_bottom_bar ();
		update_available_selection_actions ();
		search_mode = false;
	}

	[GtkCallback]
	private void update_collection_name_validity () {
		var name = collection_rename_entry.text.strip ();

		if (name == collections_page.collection_title) {
			is_collection_rename_valid = true;
			collection_rename_error_label.label = "";
		}
		else if (name == "") {
			is_collection_rename_valid = false;
			collection_rename_error_label.label = _("Collection name cannot be empty");
		}
		else if (collection_manager.does_collection_title_exist (name)) {
			is_collection_rename_valid = false;
			collection_rename_error_label.label = _("A collection with this name already exists");
		}
		else {
			is_collection_rename_valid = true;
			collection_rename_error_label.label = "";
		}

		if (is_collection_rename_valid)
			collection_rename_entry.get_style_context ().remove_class ("error");
		else
			collection_rename_entry.get_style_context ().add_class ("error");
	}

	[GtkCallback]
	private void on_collection_rename_activated () {
		assert (collections_page.current_collection is UserCollection);

		if (!is_collection_rename_valid)
			return;

		var name = collection_rename_entry.text.strip ();
		var collection = collections_page.current_collection as UserCollection;
		if (collection == null)
			return;

		collection.set_title (name);
		collections_page.collection_title = name;
		rename_popover.popdown ();
		collections_page.invalidate_sort ();
	}

	[GtkCallback]
	private void on_selected_items_changed () {
		int length = 0;

		if (viewstack.visible_child == collections_page && !collections_page.is_subpage_open) {
			var collections = collections_page.get_selected_collections ();
			length = collections.length;
			selection_action_bar.sensitive = length != 0;
		}
		else {
			var games = get_currently_selected_games ();
			length = games.length;
			selection_action_bar.update (games);
		}

		string label;
		if (length != 0)
			label = ngettext ("Selected %d item", "Selected %d items", length).printf (length);
		else
			label = _("Click on items to select them");

		selection_mode_label.label = label;
	}

	[GtkCallback]
	private void on_collection_subpage_back_clicked () {
		collections_page.exit_subpage ();
	}

	[GtkCallback]
	private void on_selection_mode_changed () {
		if (is_selection_mode) {
			header_bar_stack.visible_child = selection_mode_header_bar;

			selection_action_bar.favorite_state = SelectionActionBar.FavoriteState.NONE_FAVORITE;
		}
		else {
			select_none ();
			header_bar_stack.visible_child = collections_deck;
			if (collections_page.is_subpage_open)
				collections_deck.visible_child = collection_subpage_header_bar;
			else
				collections_deck.visible_child = platforms_deck;
		}

		update_bottom_bar ();
	}

	[GtkCallback]
	private void on_empty_collection_changed () {
		update_adaptive_state ();
		update_selection_availability ();
	}

	[GtkCallback]
	private void update_selection_availability () {
		is_selection_available = viewstack.visible_child != platforms_page || !is_folded;
	}

	[GtkCallback]
	private void on_loading_notification_closed () {
		loading_notification = false;
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (viewstack.visible_child == games_page)
			games_page.reset_scroll_position ();
		else if (viewstack.visible_child == platforms_page)
			platforms_page.reset ();
		else
			collections_page.reset_scroll_position ();

		filtering_text = null;

		if (search_mode) {
			on_search_text_notify ();
		}

		update_selection_availability ();
		update_add_game_availablity ();
		update_available_selection_actions ();
	}

	[GtkCallback]
	private void on_search_text_notify () {
		filtering_text = search_bar.text;

		bool is_search_empty;
		EmptySearch.SearchItem search_item;
		if (viewstack.visible_child != collections_page) {
			is_search_empty = games_page.is_search_empty || platforms_page.is_search_empty;
			search_item = EmptySearch.SearchItem.GAME;
		}
		else {
			is_search_empty = collections_page.is_search_empty;
			search_item = collections_page.is_subpage_open ? EmptySearch.SearchItem.GAME:
			                                                 EmptySearch.SearchItem.COLLECTION;
		}

		if (is_search_empty) {
			empty_stack.visible_child = empty_search;
			empty_search.search_item = search_item;
		}
		else
			empty_stack.visible_child = viewstack;

		// Changing the filtering_text for the PlatformsPage might
		// cause the currently selected sidebar row to become empty and therefore
		// hidden. In this case the first visible row will become selected and
		// this causes the search bar to lose focus so we have to regrab it here
		search_bar.focus_entry ();
	}

	[GtkCallback]
	private void on_search_mode_changed () {
		if (!search_mode)
			empty_stack.visible_child = viewstack;
	}

	[GtkCallback]
	private void on_folded_changed () {
		if (is_folded) {
			platforms_deck.visible_child = is_subview_open ? subview_header_bar : header_bar;
			swipe_group.add_swipeable (platforms_deck);
		} else {
			swipe_group.remove_swipeable (platforms_deck);
			platforms_deck.visible_child = header_bar;
		}

		update_bottom_bar ();
		update_selection_availability ();
	}

	[GtkCallback]
	private void update_bottom_bar () {
		view_switcher_bar.reveal = !is_selection_mode && is_showing_bottom_bar
		                           && (!is_folded || !is_subview_open)
		                           && !collections_page.is_subpage_open;
	}

	[GtkCallback]
	private void update_adaptive_state () {
		bool showing_title = view_switcher_title.title_visible;
		is_showing_bottom_bar = showing_title && !is_empty_collection;
	}

	[GtkCallback]
	private void on_subview_back_clicked () {
		platforms_deck.navigate (Hdy.NavigationDirection.BACK);
	}
}
