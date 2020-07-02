// This file is part of GNOME Games. License: GPL-3.0+.

namespace Games.Unicode {
	private enum Encoding {
		UTF_32BE,
		UTF_32LE,
		UTF_16BE,
		UTF_16LE,
		UTF_8;

		public string to_string () {
			switch (this) {
			case Encoding.UTF_32BE:
				return "utf-32be";
			case Encoding.UTF_32LE:
				return "utf-32le";
			case Encoding.UTF_16BE:
				return "utf-16be";
			case Encoding.UTF_16LE:
				return "utf-16le";
			default:
				return "utf-8";
			}
		}
	}

	private Encoding parse_encoding (FileInputStream stream, out int bom_length) throws Error {
		stream.seek (0, SeekType.SET);

		uint8[] c = { 0, 0, 0, 0 };
		var size = stream.read (c);
		if (size < 4) {
			bom_length = 0;

			return Encoding.UTF_8;
		}

		uint32 bom = c[0] | (c[1] << 8) | (c[2] << 16) | (c[3] << 24);
		if (bom == 0xfffe0000) {
			bom_length = 4;

			return Encoding.UTF_32BE;
		}
		else if (bom == 0x0000feff) {
			bom_length = 4;

			return Encoding.UTF_32LE;
		}
		else if ((bom & 0xffff) == 0xfffe) {
			bom_length = 2;

			return Encoding.UTF_16BE;
		}
		else if ((bom & 0xffff) == 0xfeff) {
			bom_length = 2;

			return Encoding.UTF_16LE;
		}
		else if ((bom & 0xffffff) == 0xbfbbef) {
			bom_length = 3;

			return Encoding.UTF_8;
		}

		bom_length = 0;

		return Encoding.UTF_8;
	}

	private InputStream read (File file, Encoding encoding) throws Error {
		var stream = file.read ();
		int bom_length = 0;
		var src_encoding = parse_encoding (stream, out bom_length);
		stream.seek (bom_length, SeekType.SET);

		if (encoding == Encoding.UTF_8)
			return stream;

		var converter = new CharsetConverter (encoding.to_string (), src_encoding.to_string ());

		return new ConverterInputStream (stream, converter);
	}
}
