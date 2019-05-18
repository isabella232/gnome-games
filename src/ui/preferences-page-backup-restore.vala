// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/preferences-page-backup-restore.ui")]
private class Games.PreferencesPageBackupRestore : PreferencesPage {
	construct {
		title = _("Back Up & Restore");
	}

	[GtkCallback]
	private void on_restore_clicked () {
		var toplevel = get_toplevel () as Gtk.Window;
		var chooser = new Gtk.FileChooserNative (_("Restore save data"), toplevel,
		                                         Gtk.FileChooserAction.OPEN,
		                                         _("_Restore"), _("_Cancel"));

		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			var archive_name = chooser.get_filename ();

			try {
				Application.restore_from (archive_name);
			}
			catch (Error e) {
				var msg = _("Couldn’t restore: %s").printf (e.message);
				show_error_message (msg);
			}
		}

		chooser.destroy ();
	}

	[GtkCallback]
	private void on_backup_clicked () {
		var toplevel = get_toplevel () as Gtk.Window;
		var chooser = new Gtk.FileChooserNative (_("Back up save data"), toplevel,
		                                        Gtk.FileChooserAction.SAVE,
		                                        _("_Back Up"), _("_Cancel"));

		chooser.do_overwrite_confirmation = true;

		var current_time = new DateTime.now_local ();
		var creation_time = current_time.format ("%c");
		var archive_filename = "gnome-games-backup-%s.tar.gz".printf (creation_time);

		chooser.set_current_name (archive_filename);

		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			var filename = chooser.get_filename ();

			try {
				Application.backup_to (filename);
			}
			catch (ArchiveError e) {
				var msg = _("Couldn’t back up: %s").printf (e.message);
				show_error_message (msg);
			}
		}

		chooser.destroy ();
	}
}
