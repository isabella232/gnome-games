// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.DesktopTrackerUriQuery : Object, TrackerUriQuery {
	public string get_query () {
		return "SELECT nie:url(?urn) WHERE { ?urn nie:isLogicalPartOf 'urn:software-category:Game' . }";
	}
}
