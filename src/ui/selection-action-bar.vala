// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/selection-action-bar.ui")]
private class Games.SelectionActionBar : Gtk.ActionBar {
	[GtkChild]
	private Gtk.Stack icon_stack;
	[GtkChild]
	private Gtk.Button favorite_button;

	private FavoriteState _favorite_state;
	public FavoriteState favorite_state {
		get { return _favorite_state; }
		set {
			_favorite_state = value;

			icon_stack.visible_child_name = favorite_state.get_child_name ();
			favorite_button.tooltip_text = favorite_state.get_tooltip_text ();
		}
	}

	public bool show_remove_button { get; set; }
	public bool show_game_actions { get; set; }
	public bool show_remove_collection_button { get; set; }

	public enum FavoriteState {
		NONE_FAVORITE,
		ALL_FAVORITE,
		SEMI_FAVORITE;

		public string get_child_name () {
			switch (this) {
			case NONE_FAVORITE:
				return "starred-icon";

			case ALL_FAVORITE:
				return "non-starred-icon";

			case SEMI_FAVORITE:
				return "semi-starred-icon";

			default:
				assert_not_reached ();
			}
		}

		public string get_tooltip_text () {
			switch (this) {
			case ALL_FAVORITE:
				return  _("Remove selected games from favorites");

			case NONE_FAVORITE:
			case SEMI_FAVORITE:
				return _("Add selected games to favorites");

			default:
				assert_not_reached ();
			}
		}
	}

	public void update (Game[] games) {
		sensitive = games.length != 0;

		if (is_all_favorite (games)) {
			favorite_state = ALL_FAVORITE;
			return;
		}

		if (is_none_favorite (games)) {
			favorite_state = NONE_FAVORITE;
			return;
		}

		favorite_state = SEMI_FAVORITE;
	}

	private bool is_all_favorite (Game[] games) {
		foreach (var game in games)
			if (!game.is_favorite)
				return false;

		return true;
	}

	private bool is_none_favorite (Game[] games) {
		foreach (var game in games)
			if (game.is_favorite)
				return false;

		return true;
	}
}
