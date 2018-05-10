// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.GenericPublisher : Object, Publisher {
	private string publisher;

	public GenericPublisher (string publisher) {
		this.publisher = publisher;
	}

	public string get_publisher () {
		return publisher;
	}
}
