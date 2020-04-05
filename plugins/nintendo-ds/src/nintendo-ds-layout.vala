// This file is part of GNOME Games. License: GPL-3.0+.

public enum Games.NintendoDsLayout {
	TOP_BOTTOM,
	LEFT_RIGHT,
	RIGHT_LEFT,
	QUICK_SWITCH;

	public string get_value () {
		switch (this) {
		case TOP_BOTTOM:
			return "top/bottom";

		case LEFT_RIGHT:
			return "left/right";

		case RIGHT_LEFT:
			return "right/left";

		case QUICK_SWITCH:
			return "quick switch";

		default:
			assert_not_reached ();
		}
	}

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
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator. This setting means the two screens are stacked one on
			 * top of the other */
			return _("Vertical");

		case LEFT_RIGHT:
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator. This setting means the two screens are displayed side
			 * by side */
			return _("Side by side");

		case RIGHT_LEFT:
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator. This setting means the two screens are displayed side
			 * by side */
			return _("Side by side");

		case QUICK_SWITCH:
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator. This setting means only one screen is displayed at
			 * once. The screen displayed can then be changed in-game. */
			return _("Single screen");

		default:
			assert_not_reached ();
		}
	}

	public string? get_subtitle () {
		switch (this) {
		case LEFT_RIGHT:
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator when the two screens are displayed side by side and not
			 * one on top of the other. The bottom screen is displayed to the
			 * right of the top screen. */
			return _("Bottom to the right");

		case RIGHT_LEFT:
			/* Translators: This describes the layout for the Nintendo DS
			 * emulator when the two screens are displayed side by side and not
			 * one on top of the other. The bottom screen is displayed to the
			 * left of the top screen. */
			return _("Bottom to the left");

		case TOP_BOTTOM:
		case QUICK_SWITCH:
			return null;

		default:
			assert_not_reached ();
		}
	}

	public static NintendoDsLayout[] get_layouts () {
		return { TOP_BOTTOM, LEFT_RIGHT, RIGHT_LEFT, QUICK_SWITCH };
	}

	public static NintendoDsLayout? from_value (string value) {
		switch (value) {
		case "top/bottom":
			return TOP_BOTTOM;

		case "left/right":
			return LEFT_RIGHT;

		case "right/left":
			return RIGHT_LEFT;

		case "quick switch":
			return QUICK_SWITCH;

		default:
			warning ("Unknown screen layout: %s\n", value);
			return null;
		}
	}
}
