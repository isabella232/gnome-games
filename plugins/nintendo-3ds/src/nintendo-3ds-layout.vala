namespace Games.Nintendo3DsLayout {
	private string get_option_value (ScreenLayout layout) {
		switch (layout) {
		case TOP_BOTTOM:
			return "Default Top-Bottom Screen";

		case LEFT_RIGHT:
		case RIGHT_LEFT:
			return "Side by Side";

		case QUICK_SWITCH:
			return "Single Screen Only";

		default:
			assert_not_reached ();
		}
	}
}
