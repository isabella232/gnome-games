// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-import-export.ui")]
private class Games.PreferencesPageImportExport : PreferencesPage {
	[GtkCallback]
	private void on_import_clicked () {
		var toplevel = get_toplevel () as Gtk.Window;
		var chooser = new Gtk.FileChooserNative (_("Import save data"), toplevel,
		                                         Gtk.FileChooserAction.OPEN,
		                                         _("_Import"), _("_Cancel"));

		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			var archive_name = chooser.get_filename ();

			try {
				Application.import_from (archive_name);
			}
			catch (ExtractionError e) {
				var msg = _("Couldn’t import save data: %s").printf (e.message);
				show_error_message (msg);
			}
		}

		chooser.destroy ();
	}

	[GtkCallback]
	private void on_export_clicked () {
		var toplevel = get_toplevel () as Gtk.Window;
		var chooser = new Gtk.FileChooserNative (_("Export save data"), toplevel,
		                                        Gtk.FileChooserAction.SAVE,
		                                        _("_Export"), _("_Cancel"));

		chooser.do_overwrite_confirmation = true;

		var current_time = new DateTime.now_local ();
		var creation_time = current_time.format ("%c");
		var archive_filename = "gnome-games-save-data-%s.tar.gz".printf (creation_time);

		chooser.set_current_name (archive_filename);

		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			var filename = chooser.get_filename ();

			try {
				Application.export_to (filename);
			}
			catch (CompressionError e) {
				var msg = _("Couldn’t export save data: %s").printf (e.message);
				show_error_message (msg);
			}
		}

		chooser.destroy ();
	}
}
