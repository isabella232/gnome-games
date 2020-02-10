// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.Media : Object {
	public Title? title { get; private set; }

	private Uri[] uris;

	public Media (Title? title = null) {
		this.title = title;
		this.uris = {};
	}

	public Media.parse (Variant variant) {
		assert (get_variant_type ().equal (variant.get_type ()));

		var title_child = variant.get_child_value (0);
		var uris_child = variant.get_child_value (1);

		var maybe_title = title_child.get_maybe ();
		if (maybe_title != null)
			title = new GenericTitle (maybe_title.get_string ());

		uris = {};
		for (int i = 0; i < uris_child.n_children (); i++) {
			var uri = uris_child.get_child_value (i).get_string ();
			uris += new Uri (uri);
		}
	}

	public Uri[] get_uris () {
		return uris;
	}

	public void add_uri (Uri uri) {
		uris += uri;
	}

	public Variant serialize () {
		Variant? title_variant = null;
		if (title != null)
			try {
				title_variant = new Variant.string (title.get_title ());
			}
			catch (Error e) {
				critical ("Couldn't get title: %s", e.message);
			}

		Variant[] uri_variants = {};
		foreach (var uri in uris)
			uri_variants += new Variant.string (uri.to_string ());

		return new Variant.tuple ({
			new Variant.maybe (VariantType.STRING, title_variant),
			new Variant.array (VariantType.STRING, uri_variants)
		});
	}

	public static VariantType get_variant_type () {
		return new VariantType.tuple ({
			new VariantType.maybe (VariantType.STRING),
			new VariantType.array (VariantType.STRING)
		});
	}
}
