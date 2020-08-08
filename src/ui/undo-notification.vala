// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/undo-notification.ui")]
private class Games.UndoNotification : Gtk.EventBox {
	private const uint NOTIFICATION_TIMEOUT_SEC = 3;

	public signal void undo ();
	public signal void closed ();

	private uint timeout_id = 0;
	private Gtk.EventControllerMotion motion_controller;

	public bool reveal { get; set; }
	public string label { get; set; }

	construct {
		motion_controller = new Gtk.EventControllerMotion (this);
		motion_controller.propagation_phase = Gtk.PropagationPhase.TARGET;
		motion_controller.enter.connect (() => {
			remove_current_timeout_if_exists ();
		});
		motion_controller.leave.connect (() => {
			set_new_timeout ();
		});
	}

	public void show_notification () {
		reveal = true;
		remove_current_timeout_if_exists ();
		set_new_timeout ();
	}

	private void set_new_timeout () {
		timeout_id = Timeout.add_seconds (NOTIFICATION_TIMEOUT_SEC, () => {
			timeout_id = 0;
			reveal = false;
			closed ();

			return Source.REMOVE;
		});
	}

	private void remove_current_timeout_if_exists () {
		if (timeout_id != 0) {
			Source.remove (timeout_id);
			timeout_id = 0;
		}
	}

	[GtkCallback]
	private void on_undo_button_clicked () {
		remove_current_timeout_if_exists ();
		reveal = false;
		undo ();
	}

	[GtkCallback]
	private void on_notification_closed () {
		remove_current_timeout_if_exists ();
		reveal = false;
		closed ();
	}
}
