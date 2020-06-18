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

	private bool _is_empty_collection;
	public bool is_empty_collection {
		get { return _is_empty_collection; }
		set {
			_is_empty_collection = value;

			if (is_empty_collection)
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

	public bool is_search_mode { get; set; }
	public bool is_subpage_open { get; set; }
	public bool is_selection_mode { get; set; }
	public bool can_swipe_back { get; set; }
	public string collection_title { get; set; }

	construct {
		collections_main_page.gamepad_accepted.connect (() => {
			collections_subpage.select_default_game (Gtk.DirectionType.RIGHT);
		});
		collections_subpage.selected_items_changed.connect (() => {
			selected_items_changed ();
		});
		update_can_swipe_back ();
	}

	public void select_all () {
		if (is_subpage_open)
			collections_subpage.select_all ();
	}

	public void select_none () {
		if (is_subpage_open)
			collections_subpage.select_none ();
	}

	public Game[] get_selected_games () {
		return collections_subpage.get_selected_games ();
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

	public void update_is_empty_collection () {
		is_empty_collection = collections_subpage.game_model.get_n_items () == 0;
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

	[GtkCallback]
	private bool on_subpage_back_clicked () {
		if (!is_subpage_open)
			return false;

		is_search_mode = false;
		collections_deck.visible_child = collections_main_page;
		return true;
	}

	[GtkCallback]
	private void on_collection_activated (Collection collection) {
		collection_title = collection.get_title ();
		collections_deck.visible_child = collections_subpage_stack;

		is_empty_collection = collection.get_game_model ().get_n_items () == 0;
		if (is_empty_collection)
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
