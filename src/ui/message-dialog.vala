// This file is part of GNOME Games. License: GPL-3.0+.

[GtkTemplate (ui = "/org/gnome/Games/ui/message-dialog.ui")]
private class Games.MessageDialog : Gtk.Dialog {
	[GtkChild]
	private Gtk.Label label;
	[GtkChild]
	private Gtk.Label secondary_label;
	[GtkChild]
	private Gtk.Box title_box;

	private string _text;
	public string text {
		get { return _text; }
		set {
			_text = value;
			label.label = value;
		}
	}

	private string _secondary_text;
	public string? secondary_text {
		get { return _secondary_text; }
		set {
			_secondary_text = value;
			secondary_label.label = value;
			secondary_label.visible = (value != null);
		}
	}

	construct {
		// FIXME: There's no way to avoid this in GTK3
		var action_area = get_action_area () as Gtk.ButtonBox;
		action_area.set_layout (Gtk.ButtonBoxStyle.EXPAND);
	}

	static construct {
		set_css_name ("messagedialog");
	}

	public override void constructed () {
		base.constructed ();

		set_titlebar (title_box);
	}

	public bool gamepad_button_press_event (Manette.Event event) {
		if (!visible)
			return false;

		uint16 button;
		if (!event.get_button (out button))
			return false;

		switch (button) {
		case EventCode.BTN_A:
			response (Gtk.ResponseType.ACCEPT);

			return true;
		case EventCode.BTN_B:
			response (Gtk.ResponseType.CANCEL);

			return true;
		default:
			return false;
		}
	}
}
