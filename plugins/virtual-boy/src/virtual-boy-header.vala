// This file is part of GNOME Games. License: GPL-3.0+.

// Documentation: https://www.planetvb.com/content/downloads/documents/stsvb.html
private class Games.VirtualBoyHeader : Object {
	private const size_t MAGIC_OFFSET = 0x20C;
	private const uint8[] MAGIC_VALUE = { 0, 0, 0, 0, 0 };

	private File file;

	public VirtualBoyHeader (File file) {
		this.file = file;
	}

	public void check_validity () throws VirtualBoyError {
		var stream = get_stream ();
		var size = get_file_size ();
		ssize_t read = 0;

		if (size < MAGIC_OFFSET)
			throw new VirtualBoyError.INVALID_FILE ("The file is too short.");

		try {
			stream.seek (size - MAGIC_OFFSET, SeekType.SET);
		}
		catch (Error e) {
			throw new VirtualBoyError.INVALID_SIZE ("Invalid Virtual Boy ROM header size: %s", e.message);
		}

		var buffer = new uint8[MAGIC_VALUE.length];
		try {
			read = stream.read (buffer);
		}
		catch (Error e) {
			throw new VirtualBoyError.INVALID_SIZE (e.message);
		}

		if (read < MAGIC_VALUE.length)
			throw new VirtualBoyError.INVALID_SIZE ("Invalid Virtual Boy ROM header size.");

		for (var i = 0; i < MAGIC_VALUE.length; i++)
			if (buffer[i] != MAGIC_VALUE[i])
				throw new VirtualBoyError.INVALID_HEADER ("The file doesn’t have a Virtual Boy ROM header.");
	}

	private int64 get_file_size () throws VirtualBoyError {
		try {
			var info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
			return info.get_size ();
		}
		catch (Error e) {
			throw new VirtualBoyError.CANT_READ_FILE ("Couldn’t get file size: %s", e.message);
		}
	}

	private FileInputStream get_stream () throws VirtualBoyError {
		try {
			return file.read ();
		}
		catch (Error e) {
			throw new VirtualBoyError.CANT_READ_FILE ("Couldn’t read file: %s", e.message);
		}
	}
}

errordomain Games.VirtualBoyError {
	CANT_READ_FILE,
	INVALID_FILE,
	INVALID_SIZE,
	INVALID_HEADER,
}
