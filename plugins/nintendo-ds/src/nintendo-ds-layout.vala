namespace Games.NintendoDsLayout {
	private string get_value (ScreenLayout layout) {
		switch (layout) {
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

	private static ScreenLayout? from_value (string value) {
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
