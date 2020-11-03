// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Gdi : Object {
	private const string NEW_LINE = "\n";

	public File file { get; construct; }

	public uint tracks_number {
		get {
			assert (parsed);

			return tracks.length;
		}
	}

	private bool parsed = false;
	private GdiTrackNode[] tracks;

	public Gdi (File file) {
		Object (file: file);
	}

	public GdiTrackNode get_track (uint i) throws Error {
		assert (parsed);

		if (i >= tracks.length)
			throw new GdiError.NOT_A_TRACK ("“%s” doesn’t have a track for index %u.", file.get_uri (), i);

		return tracks[i];
	}

	private string[] tokenize () throws Error {
		var stream = Unicode.read (file, Unicode.Encoding.UTF_8);
		var data_stream = new DataInputStream (stream);

		string[] tokens = {};

		string? line;
		while ((line = data_stream.read_line_utf8 ()) != null)
			foreach (var token in tokenize_line (line))
				tokens += token;

		return tokens;
	}

	private static Regex token_regex;
	private static string[] tokenize_line (string line) {
		if (token_regex == null)
			// Matches words or "double quoted strings" (no escaping).
			token_regex = /\s*([^"\s]+)|(".+?")\s*/;

		string[] tokens = {};
		foreach (var token in token_regex.split (line))
			switch (token) {
			case "\r":
			case "\r\n":
				tokens += NEW_LINE;

				break;
			case "":
			case " ":
				break;
			default:
				tokens += token;

				break;
			}

		// Makes sure the token set ends by a new line.
		if (tokens.length != 0 && tokens[tokens.length - 1] != NEW_LINE)
			tokens += NEW_LINE;

		return tokens;
	}

	public void parse () throws Error {
		assert (!parsed);

		parsed = true;

		var tokens = tokenize ();

		size_t line = 1;
		for (size_t i = 0; i < tokens.length; line++)
			// Each case must consume the line completely.
			if (line == 1)
				parse_track_count_line (ref tokens, ref i, line);
			else
				tracks += parse_track_line (ref tokens, ref i, line);
	}

	private void parse_track_count_line (ref string[] tokens, ref size_t i, size_t line) throws GdiError {
		// Skip the track number token.
		skip_token (ref tokens, ref i, line);
		is_end_of_line (ref tokens, ref i, line);
	}

	private GdiTrackNode parse_track_line (ref string[] tokens, ref size_t i, size_t line) throws GdiError {
		var track_number_string = get_token (ref tokens, ref i, line);

		// Skip the track offset token.
		skip_token (ref tokens, ref i, line);

		// Skip the track mode tokens.
		skip_token (ref tokens, ref i, line);
		skip_token (ref tokens, ref i, line);

		var file_name = get_token (ref tokens, ref i, line);
		if (file_name.has_prefix ("\"") && file_name.has_suffix ("\"") && file_name.length > 1)
			file_name = file_name[1: file_name.length - 1];
		var dir = file.get_parent ();
		var child_file = dir.get_child (file_name);

		// Skip the unknown token.
		skip_token (ref tokens, ref i, line);
		is_end_of_line (ref tokens, ref i, line);

		var track_number = int.parse (track_number_string);
		if (track_number < 1 || track_number > 99)
			throw new GdiError.INVALID_TRACK_NUMBER ("%s:%lu: Invalid track number %s, expected a number in the 1-99 range.", file.get_basename (), line, track_number_string);

		return GdiTrackNode () { file = child_file, track_number = track_number };
	}

	private void skip_token (ref string[] tokens, ref size_t i, size_t line) throws GdiError {
		if (i >= tokens.length)
			throw new GdiError.UNEXPECTED_EOF ("%s:%lu: Unexpected end of file, expected a token.", file.get_basename (), line);

		if (tokens[i] == NEW_LINE)
			throw new GdiError.UNEXPECTED_EOL ("%s:%lu: Unexpected end of line, expected a token.", file.get_basename (), line);

		i++;
	}

	private string get_token (ref string[] tokens, ref size_t i, size_t line) throws GdiError {
		if (i >= tokens.length)
			throw new GdiError.UNEXPECTED_EOF ("%s:%lu: Unexpected end of file, expected a token.", file.get_basename (), line);

		if (tokens[i] == NEW_LINE)
			throw new GdiError.UNEXPECTED_EOL ("%s:%lu: Unexpected end of line, expected a token.", file.get_basename (), line);

		return tokens[i++];
	}

	private void is_end_of_line (ref string[] tokens, ref size_t i, size_t line) throws GdiError {
		if (i < tokens.length && tokens[i] != NEW_LINE)
			throw new GdiError.UNEXPECTED_TOKEN ("%s:%lu: Unexpected token %s, expected end of line.", file.get_basename (), line, tokens[i]);

		i++;
	}
}

public struct Games.GdiTrackNode {
	public File file;
	public int track_number;
}

private errordomain Games.GdiError {
	UNEXPECTED_TOKEN,
	UNEXPECTED_EOL,
	UNEXPECTED_EOF,
	INVALID_TRACK_NUMBER,
	INVALID_TRACK_MODE,
	NOT_A_TRACK,
}
