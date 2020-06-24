// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/snapshot-row.ui")]
private class Games.SnapshotRow : Gtk.ListBoxRow {
	[GtkChild]
	private SnapshotThumbnail thumbnail;
	[GtkChild]
	private Gtk.Label name_label;
	[GtkChild]
	private Gtk.Label date_label;
	[GtkChild]
	private Gtk.Revealer revealer;

	private Snapshot _snapshot;
	public Snapshot snapshot {
		get { return _snapshot; }
		set {
			_snapshot = value;

			if (snapshot.is_automatic)
				name_label.label = _("Autosave");
			else
				name_label.label = snapshot.name;

			var creation_date = snapshot.creation_date;
			var date_format = get_date_format (creation_date);
			date_label.label = creation_date.format (date_format);

			thumbnail.snapshot = snapshot;
		}
	}

	public SnapshotRow (Snapshot snapshot) {
		Object (snapshot: snapshot);
	}

	public void set_name (string name) {
		name_label.label = name;
		snapshot.name = name;

		try {
			snapshot.write_metadata ();
		}
		catch (Error e) {
			critical ("Couldn't update snapshot name: %s", e.message);
		}
	}

	public void reveal () {
		revealer.reveal_child = true;
	}

	public void remove_animated () {
		selectable = false;
		revealer.notify["child-revealed"].connect (() => {
			get_parent ().remove (this);
		});
		revealer.reveal_child = false;
	}

	// Adapted from nautilus-file.c, nautilus_file_get_date_as_string()
	private string get_date_format (DateTime date) {
		var date_midnight = new DateTime.local (date.get_year (),
		                                        date.get_month (),
		                                        date.get_day_of_month (),
		                                        0, 0, 0);
		var now = new DateTime.now ();
		var today_midnight = new DateTime.local (now.get_year (), now.get_month (), now.get_day_of_month (), 0, 0, 0);
		var days_ago = (today_midnight.difference (date_midnight)) / GLib.TimeSpan.DAY;

		if (days_ago == 0) {
			/* Translators: Time in locale format */
			/* xgettext:no-c-format */
			return _("%X");
		}
		else if (days_ago == 1) {
			/* Translators: this is the word Yesterday followed by
			 * a time in locale format. i.e. "Yesterday 23:04:35" */
			/* xgettext:no-c-format */
			return _("Yesterday %X");
		}
		else if (days_ago > 1 && days_ago < 7) {
			/* Translators: this is the abbreviated name of the week day followed by
			 * a time in locale format. i.e. "Monday 23:04:35" */
			/* xgettext:no-c-format */
			return _("%a %X");
		}
		else if (date.get_year () == now.get_year ()) {
			/* Translators: this is the day of the month followed
			 * by the abbreviated month name followed by a time in
			 * locale format i.e. "3 Feb 23:04:35" */
			/* xgettext:no-c-format */
			return _("%-e %b %X");
		}
		else {
			/* Translators: this is the day number followed
			 * by the abbreviated month name followed by the year followed
			 * by a time in locale format i.e. "3 Feb 2015 23:04:00" */
			/* xgettext:no-c-format */
			return _("%-e %b %Y %X");
		}
	}
}
