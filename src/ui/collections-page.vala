// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collections-page.ui")]
private class Games.CollectionsPage : Gtk.Bin {
	public signal void game_activated (Game game);
	public signal void selected_items_changed ();

	[GtkChild]
	private Hdy.Deck collections_deck;
	[GtkChild]
	private CollectionsMainPage collections_main_page;
	[GtkChild]
	private Gtk.Stack collections_subpage_stack;
	[GtkChild]
	private GamesPage collections_subpage;
	[GtkChild]
	private CollectionEmpty collection_empty_subpage;

	private UserCollection[]? last_removed_collections;
	private CollectionManager collection_manager;

	private bool _is_collection_empty;
	public bool is_collection_empty {
		get { return _is_collection_empty; }
		set {
			_is_collection_empty = value;

			if (is_collection_empty)
				collections_subpage_stack.visible_child = collection_empty_subpage;
			else
				collections_subpage_stack.visible_child = collections_subpage;
		}
	}

	public CollectionModel collection_model {
		get { return collections_main_page.collection_model; }
		set {
			collections_main_page.collection_model = value;
		}
	}

	private Collection? _current_collection;
	public Collection? current_collection {
		get { return _current_collection; }
		set {
			_current_collection = value;

			is_showing_user_collection = current_collection != null &&
			                             current_collection.get_collection_type () ==
			                             Collection.CollectionType.USER;
		}
	}

	public ApplicationWindow application_window { get; set; }
	public bool is_search_mode { get; set; }
	public bool is_subpage_open { get; set; }
	public bool is_selection_mode { get; set; }
	public bool is_showing_user_collection { get; set; }
	public bool can_swipe_back { get; set; }
	public string collection_title { get; set; }
	public string removed_notification_title { get; set; }

	construct {
		collection_manager = Application.get_default ().get_collection_manager ();

		collections_main_page.gamepad_accepted.connect (() => {
			collections_subpage.select_default_game (Gtk.DirectionType.RIGHT);
		});
		collections_subpage.selected_items_changed.connect (() => {
			selected_items_changed ();
		});
		collections_main_page.selected_items_changed.connect (() => {
			selected_items_changed ();
		});
		update_can_swipe_back ();
	}

	public void select_all () {
		if (is_subpage_open)
			collections_subpage.select_all ();
		else
			collections_main_page.select_all ();
	}

	public void select_none () {
		if (is_subpage_open)
			collections_subpage.select_none ();
		else
			collections_main_page.select_none ();
	}

	public Game[] get_selected_games () {
		return collections_subpage.get_selected_games ();
	}

	public UserCollection[] get_selected_collections () {
		return collections_main_page.get_selected_collections ();
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		return is_subpage_open ? collections_subpage.gamepad_button_press_event (event) :
		                         collections_main_page.gamepad_button_press_event (event);
	}

	public bool gamepad_button_release_event (Manette.Event event) {
		return is_subpage_open ? collections_subpage.gamepad_button_release_event (event) :
		                         collections_main_page.gamepad_button_release_event (event);
	}

	public bool gamepad_absolute_axis_event (Manette.Event event) {
		return is_subpage_open ? collections_subpage.gamepad_absolute_axis_event (event) :
		                         collections_main_page.gamepad_absolute_axis_event (event);
	}

	public void reset_scroll_position () {
		if (is_subpage_open)
			collections_subpage.reset_scroll_position ();
		else
			collections_main_page.reset_scroll_position ();
	}

	public void update_is_collection_empty () {
		is_collection_empty = collections_subpage.game_model.get_n_items () == 0;
	}

	public void set_filter (string[] filtering_terms) {
		if (is_subpage_open)
			collections_subpage.set_filter (filtering_terms);
	}

	public Hdy.Deck get_collections_deck () {
		return collections_deck;
	}

	public bool exit_subpage () {
		return on_subpage_back_clicked ();
	}

	public void invalidate_filter () {
		collections_main_page.invalidate_filter ();
	}

	public void invalidate_sort () {
		collections_main_page.invalidate_sort ();
	}

	public void remove_current_user_collection () {
		if (!is_showing_user_collection || current_collection == null)
			return;

		remove_collections ({ current_collection as UserCollection });
		on_subpage_back_clicked ();
	}

	public void remove_currently_selected_user_collections () {
		remove_collections (collections_main_page.get_selected_collections ());
	}

	public void undo_remove_collection () {
		if (last_removed_collections == null)
			return;

		foreach (var collection in last_removed_collections) {
			collection_model.add_collection (collection);
			collection.games_changed ();
		}

		last_removed_collections = null;
	}

	public void finalize_collection_removal () {
		if (last_removed_collections == null)
			return;

		foreach (var collection in last_removed_collections)
			collection_manager.remove_user_collection (collection);

		last_removed_collections = null;
	}

	private void remove_collections (UserCollection[] collections) {
		if (collections.length == 0)
			return;

		finalize_collection_removal ();

		foreach (var collection in collections)
			collection_model.remove_collection (collection);

		removed_notification_title = collections.length == 1 ?
		                             _("%s removed").printf (collections[0].title) :
		                             ngettext ("Removed %d collection", "Removed %d collections", collections.length)
		                             .printf (collections.length);

		last_removed_collections = collections;
	}

	[GtkCallback]
	private bool on_subpage_back_clicked () {
		if (!is_subpage_open)
			return false;

		is_search_mode = false;
		collections_deck.visible_child = collections_main_page;
		current_collection = null;
		return true;
	}

	[GtkCallback]
	private void on_collection_activated (Collection collection) {
		if (collection.get_collection_type () ==
		    Collection.CollectionType.PLACEHOLDER) {
				// Finalize any pending removal of collection and dismiss undo notification if shown.
				finalize_collection_removal ();

				var dialog = new CollectionActionWindow ();
				dialog.transient_for = get_toplevel () as ApplicationWindow;
				dialog.modal = true;
				dialog.visible = true;
				return;
		}

		current_collection = collection;
		collection_title = collection.title;
		collections_deck.visible_child = collections_subpage_stack;

		is_collection_empty = collection.get_game_model ().get_n_items () == 0;
		if (is_collection_empty)
			return;

		collections_subpage.hide_stars = collection.get_hide_stars ();
		collections_subpage.game_model = collection.get_game_model ();
		collections_subpage.reset_scroll_position ();
	}

	[GtkCallback]
	private void on_game_activated (Game game) {
		game_activated (game);
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		is_subpage_open = collections_deck.visible_child == collections_subpage_stack;
	}

	[GtkCallback]
	private void update_can_swipe_back () {
		can_swipe_back = !is_search_mode && !is_selection_mode;
	}
}
