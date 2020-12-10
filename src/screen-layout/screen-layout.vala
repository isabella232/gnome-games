// This file is part of GNOME Games. License: GPL-3.0+.

public enum Games.ScreenLayout {
	TOP_BOTTOM,
	LEFT_RIGHT,
	RIGHT_LEFT,
	QUICK_SWITCH;

	public string get_icon () {
		switch (this) {
		case TOP_BOTTOM:
			return "screen-layout-top-bottom-symbolic";

		case LEFT_RIGHT:
			return "screen-layout-left-right-symbolic";

		case RIGHT_LEFT:
			return "screen-layout-right-left-symbolic";

		case QUICK_SWITCH:
			return "screen-layout-quick-switch-symbolic";

		default:
			assert_not_reached ();
		}
	}

	public string get_title () {
		switch (this) {
		case TOP_BOTTOM:
			/* Translators: This describes the layout for the Nintendo DS and
			 * 3DS emulators. This setting means the two screens are stacked one
			 * on top of the other. */
			return _("Vertical");

		case LEFT_RIGHT:
			/* Translators: This describes the layout for the Nintendo DS and
			 * 3DS emulators. This setting means the two screens are displaye
			 * side by side and not one on top of the other. The bottom screen
			 * (which is the touch screen) is displayed to the right of the top
			 * screen, making it comfortable for right-handed persons. */
			return _("Side by side, right-handed");

		case RIGHT_LEFT:
			/* Translators: This describes the layout for the Nintendo DS and
			 * 3DS emulators. This setting means the two screens are displayed
			 * side by side and not one on top of the other. The bottom screen
			 * (which is the touch screen) is displayed to the left of the top
			 * screen, making it comfortable for left-handed persons. */
			return _("Side by side, left-handed");

		case QUICK_SWITCH:
			/* Translators: This describes the layout for the Nintendo DS and
			 * 3DS emulators. This setting means only one screen is displayed at
			 * once. The screen displayed can then be changed in-game. */
			return _("Single screen");

		default:
			assert_not_reached ();
		}
	}

	public static ScreenLayout[] get_layouts () {
		return { TOP_BOTTOM, LEFT_RIGHT, RIGHT_LEFT, QUICK_SWITCH };
	}
}
