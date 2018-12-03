// This file is part of GNOME Games. License: GPL-3.0+.

int main (string[] args) {
	Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
	Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain (Config.GETTEXT_PACKAGE);

	Grl.init (ref args);
	Hdy.init (ref args);

	var app = new Games.Application ();
	var result = app.run (args);

	Grl.deinit ();

	return result;
}
