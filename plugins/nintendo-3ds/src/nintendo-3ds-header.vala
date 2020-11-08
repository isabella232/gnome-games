// This file is part of GNOME Games. License: GPL-3.0+.

// Documentation: https://www.planetvb.com/content/downloads/documents/stsvb.html
private class Games.Nintendo3DsHeader : Object {
	private const size_t MAGIC_OFFSET = 0x189;
	private const uint8 MAGIC_VALUE = 0;

	private File file;

	public Nintendo3DsHeader (File file) {
		this.file = file;
	}

	public void check_validity () throws Nintendo3DSError {
		var stream = get_stream ();
		ssize_t read = 0;

		try {
			stream.seek (MAGIC_OFFSET, SeekType.SET);
		}
		catch (Error e) {
			throw new Nintendo3DSError.INVALID_SIZE ("Invalid Nintendo 3DS ROM header size: %s", e.message);
		}

		var buffer = new uint8[1];
		try {
			read = stream.read (buffer);
		}
		catch (Error e) {
			throw new Nintendo3DSError.INVALID_SIZE (e.message);
		}

		if (read < 1)
			throw new Nintendo3DSError.INVALID_SIZE ("Invalid Nintendo 3DS ROM header size.");

		if (buffer[0] != MAGIC_VALUE)
			throw new Nintendo3DSError.ROM_ENCRYPTED ("The ROM is encrypted.");
	}

	private FileInputStream get_stream () throws Nintendo3DSError {
		try {
			return file.read ();
		}
		catch (Error e) {
			throw new Nintendo3DSError.CANT_READ_FILE ("Couldn’t read file: %s", e.message);
		}
	}
}

errordomain Games.Nintendo3DSError {
	CANT_READ_FILE,
	INVALID_FILE,
	INVALID_SIZE,
	ROM_ENCRYPTED,
}
