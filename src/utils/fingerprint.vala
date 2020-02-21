// This file is part of GNOME Games. License: GPL-3.0+.

namespace Games.Fingerprint {
	private string get_for_file_uri (Uri uri, size_t start, size_t? length) throws Error {
		var file = uri.to_file ();
		var istream = file.read ();

		return get_for_file_input_stream (istream, start, length);
	}

	private string get_for_file_input_stream (FileInputStream file_stream, size_t start, size_t? length) throws Error {
		size_t size;
		if (length == null) {
			file_stream.seek (0, SeekType.END);
			size = (size_t) file_stream.tell ();
		}
		else
			size = length;

		file_stream.seek (start, SeekType.SET);
		var bytes = file_stream.read_bytes (size);

		return Checksum.compute_for_bytes (ChecksumType.MD5, bytes);
	}

	public string get_uid (Uri uri, string prefix) throws Error {
		var fingerprint = Fingerprint.get_for_file_uri (uri, 0, null);

		return @"$prefix-$fingerprint";
	}

	public string get_uid_for_chunk (Uri uri, string prefix, size_t start, size_t length) throws Error {
		var fingerprint = Fingerprint.get_for_file_uri (uri, start, length);

		return @"$prefix-$fingerprint";
	}
}
