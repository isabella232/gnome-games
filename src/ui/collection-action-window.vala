// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/collection-action-window.ui")]
private class Games.CollectionActionWindow : Hdy.Window {
	public signal void confirmed (Collection[] collections);

	[GtkChild]
	private Hdy.Deck deck;
	[GtkChild]
	private Gtk.Box add_to_collection_page;
	[GtkChild]
	private Gtk.Box create_collection_page;
	[GtkChild]
	private Gtk.Stack user_collections_page_stack;
	[GtkChild]
	private Gtk.ScrolledWindow list_page;
	[GtkChild]
	private Hdy.StatusPage empty_page;
	[GtkChild]
	private Gtk.Entry name_entry;
	[GtkChild]
	private Gtk.Label error_label;
	[GtkChild]
	private Gtk.ListBox list_box;
	[GtkChild]
	private Hdy.SearchBar search_bar;
	[GtkChild]
	private Gtk.SearchEntry search_entry;
	[GtkChild]
	private Gtk.ListBoxRow add_row;

	private CollectionManager collection_manager;
	private SimpleActionGroup action_group;
	private const ActionEntry[] action_entries = {
		{ "go-back",           go_back },
		{ "new-collection",    new_collection },
		{ "create-collection", create_collection },
		{ "add-to-collection", add_to_collection }
	};

	public string[] filtering_terms;
	private string filtering_text {
		set {
			if (value == null)
				filtering_terms = null;
			else
				filtering_terms = value.split (" ");

			list_box.invalidate_filter ();
		}
	}

	private CollectionModel _collection_model;
	public CollectionModel collection_model {
		get { return _collection_model; }
		set {
			_collection_model = value;

			list_box.bind_model (collection_model, add_collection_row);
			list_box.set_filter_func (list_box_filter);
			list_box.invalidate_filter ();
		}
	}

	private bool _is_user_collections_empty;
	public bool is_user_collections_empty {
		get { return _is_user_collections_empty; }
		set {
			_is_user_collections_empty = value;

			if (is_user_collections_empty)
				user_collections_page_stack.visible_child = empty_page;
			else
				user_collections_page_stack.visible_child = list_page;
		}
	}

	public bool is_search_mode { get; set; }
	public bool is_collection_name_valid { get; set; }
	public bool create_collection_page_only { get; construct; }
	public Collection insensitive_collection { get; construct; }

	construct {
		if (create_collection_page_only)
			deck.visible_child = create_collection_page;
		else
			deck.visible_child = add_to_collection_page;

		collection_manager = Application.get_default ().get_collection_manager ();

		is_user_collections_empty = collection_manager.n_user_collections == 0;
		collection_manager.collection_added.connect ((collection) => {
			is_user_collections_empty = collection_manager.n_user_collections == 0;
		});

		action_group = new SimpleActionGroup ();
		action_group.add_action_entries (action_entries, this);
		insert_action_group ("collection-action", action_group);

		search_bar.connect_entry (search_entry);
	}

	public CollectionActionWindow (bool create_collection_page_only = true, Collection? collection = null) {
		Object (create_collection_page_only : create_collection_page_only, insensitive_collection : collection);
	}

	private Gtk.Widget add_collection_row (Object object) {
		var collection = object as Collection;
		if (collection.get_collection_type () == CollectionType.PLACEHOLDER)
			return add_row;

		var row = new CollectionListItem (collection);
		row.sensitive = collection != insensitive_collection;
		row.show ();

		return row;
	}

	private bool list_box_filter (Gtk.ListBoxRow row) {
		bool show_row;

		if (row is CollectionListItem) {
			var list_item = row as CollectionListItem;
			var collection = list_item.collection;
			var type = collection.get_collection_type ();

			show_row = (type == CollectionType.USER) &&
				       ((is_search_mode && collection.matches_search_terms (filtering_terms)) ||
				        (!is_search_mode));
		}
		else
			show_row = !is_search_mode || filtering_terms.length == 0;

		row.visible = show_row;
		return show_row;
	}

	private void add_to_collection () {
		Collection[] collections = {};

		foreach (var child in list_box.get_children ()) {
			var row = child as CollectionListItem;
			if (row == null || row.collection.get_collection_type () != CollectionType.USER)
				continue;

			var check_button = row.activatable_widget as Gtk.CheckButton;
			if (check_button.active)
				collections += row.collection;
		}

		confirmed (collections);
		close ();
	}

	private void new_collection () {
		deck.navigate (Hdy.NavigationDirection.FORWARD);
	}

	private void go_back () {
		if (create_collection_page_only || !deck.navigate (Hdy.NavigationDirection.BACK))
			close ();
	}

	[GtkCallback]
	private void create_collection () {
		if (!is_collection_name_valid)
			return;

		collection_manager.create_user_collection (name_entry.text.strip ());
		go_back ();
	}

	[GtkCallback]
	private void on_listbox_row_activated (Gtk.ListBoxRow row) {
		if (row == add_row)
			new_collection ();
	}

	[GtkCallback]
	public bool on_key_pressed (Gdk.EventKey event) {
		var default_modifiers = Gtk.accelerator_get_default_mod_mask ();

		uint keyval;
		var keymap = Gdk.Keymap.get_for_display (get_display ());
		keymap.translate_keyboard_state (event.hardware_keycode, event.state,
		                                 event.group, out keyval, null, null, null);

		if (keyval == Gdk.Key.Escape) {
			if (deck.visible_child == create_collection_page) {
				go_back ();
				return Gdk.EVENT_STOP;
			}

			if (is_search_mode) {
				is_search_mode = false;
				return Gdk.EVENT_STOP;
			}

			go_back ();
			return Gdk.EVENT_STOP;
		}

		if (((event.state & default_modifiers) == Gdk.ModifierType.MOD1_MASK) &&
		   (((get_direction () == Gtk.TextDirection.LTR) && keyval == Gdk.Key.Left) ||
		    ((get_direction () == Gtk.TextDirection.RTL) && keyval == Gdk.Key.Right)) &&
		    !create_collection_page_only && deck.navigate (Hdy.NavigationDirection.BACK))
			return Gdk.EVENT_STOP;

		if (is_user_collections_empty)
			return Gdk.EVENT_PROPAGATE;

		if (deck.visible_child == add_to_collection_page &&
		    (keyval == Gdk.Key.f || keyval == Gdk.Key.F) &&
		    (event.state & default_modifiers) == Gdk.ModifierType.CONTROL_MASK) {
			is_search_mode = !is_search_mode;
			return Gdk.EVENT_STOP;
		}

		return search_bar.handle_event (event);
	}

	[GtkCallback]
	private void on_collection_name_entry_changed () {
		var name = name_entry.text.strip ();
		if (name == "") {
			error_label.label = _("Collection name cannot be empty");
			name_entry.get_style_context ().add_class ("error");
			is_collection_name_valid = false;
			return;
		}

		if (collection_manager.does_collection_title_exist (name)) {
			error_label.label = _("A collection with this name already exists");
			name_entry.get_style_context ().add_class ("error");
			is_collection_name_valid = false;
			return;
		}

		name_entry.get_style_context ().remove_class ("error");
		error_label.label = null;
		is_collection_name_valid = true;
	}

	[GtkCallback]
	private void on_visible_child_changed () {
		if (deck.visible_child == create_collection_page) {
			name_entry.text = "";
			error_label.label = "";
			name_entry.get_style_context ().remove_class ("error");
			name_entry.grab_focus_without_selecting ();
		}
	}

	[GtkCallback]
	private void on_search_text_notify () {
		filtering_text = search_entry.text;
		search_entry.grab_focus_without_selecting ();
	}
}
