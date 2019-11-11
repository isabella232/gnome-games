// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.RetroRunnerBuilder : Object {
	public Uid uid { get; set; }
	public string title { get; set; }

	private RetroCoreSource _core_source;
	public RetroCoreSource core_source {
		get { return _core_source; }
		set {
			_core_source = value;

			if (core_source != null)
				platform = core_source.get_platform ();
		}
	}

	private Uri _uri;
	public Uri uri {
		get { return _uri; }
		set {
			_uri = value;

			if (uri != null) {
				var game_media = new Media ();
				game_media.add_uri (uri);

				media_set = new MediaSet ();
				media_set.add_media (game_media);
			}
		}
	}

	public MediaSet media_set { get; set; }

	public Retro.CoreDescriptor core_descriptor { get; set; }
	public Platform platform { get; set; }

	public InputCapabilities input_capabilities { get; set; }

	construct {
		platform = null;
		core_source = null;
		core_descriptor = null;
		input_capabilities = null;
		media_set = new MediaSet ();
	}

	public RetroRunner to_runner (Type type = typeof (RetroRunner)) {
		return_val_if_fail (uid != null, null);
		return_val_if_fail (title != null, null);
		return_val_if_fail (platform != null, null);

		return Object.new (type, "builder", this, null) as RetroRunner;
	}
}
