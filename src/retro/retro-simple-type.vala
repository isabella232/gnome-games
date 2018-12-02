// This file is part of GNOME Games. License: GPL-3.0+.

private struct Games.RetroSimpleType {
	string mime_type;
	bool search_mime_type;
	string platform;
	string prefix;

	// FIXME: These should be specified in RETRO_SIMPLE_TYPES
	public string? get_platform_name () {
		switch (platform) {
		case "Amiga":
			return _("Amiga");
		case "Atari2600":
			return _("Atari 2600");
		case "Atari7800":
			return _("Atari 7800");
		case "AtariLynx":
			return _("Atari Lynx");
		case "DOOM":
			return _("DOOM");
		case "FamicomDiskSystem":
			/* translators: only released in eastern Asia */
			return _("Famicom Disk System");
		case "GameBoy":
			return _("Game Boy");
		case "GameBoyColor":
			return _("Game Boy Color");
		case "GameBoyAdvance":
			return _("Game Boy Advance");
		case "GameGear":
			return _("Game Gear");
		case "MasterSystem":
			/* translators: also known as "Sega Mark III" in eastern asia */
			return _("Master System");
		case "NeoGeoPocket":
			return _("Neo Geo Pocket");
		case "NeoGeoPocketColor":
			return _("Neo Geo Pocket Color");
		case "NintendoEntertainmentSystem":
			/* translators: known as "Famicom" in eastern Asia */
			return _("Nintendo Entertainment System");
		case "Nintendo64":
			return _("Nintendo 64");
		case "Sega32X":
			/* translators: known as "Mega Drive 32X", "Mega 32X" or "Super 32X" in other places */
			return _("Genesis 32X");
		case "SegaGenesis":
			/* translators: known as "Mega Drive" in most of the world */
			return _("Sega Genesis");
		case "SegaPico":
			return _("Sega Pico");
		case "SG1000":
			return _("SG-1000");
		case "SuperNintendoEntertainmentSystem":
			/* translators: known as "Super Famicom" in eastern Asia */
			return _("Super Nintendo Entertainment System");
		case "TurboGrafx16":
			/* translators: known as "PC Engine" in eastern Asia and France */
			return _("TurboGrafx-16");
		case "WiiWare":
			return _("WiiWare");
		case "WonderSwan":
			return _("WonderSwan");
		case "WonderSwanColor":
			return _("WonderSwan Color");
		default:
			return null;
		}
	}
}
