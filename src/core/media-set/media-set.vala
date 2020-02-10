// This file is part of GNOME Games. License: GPL-3.0+.

public class Games.MediaSet : Object {
	public delegate void MediaCallback (Media media);

	public int selected_media_number { get; set; default = 0; }
	public string icon_name { get; set; }

	private Media[] medias;

	public MediaSet.parse (Variant variant) {
		assert (get_variant_type ().equal (variant.get_type ()));

		var icon_child = variant.get_child_value (0);
		var medias_child = variant.get_child_value (1);

		icon_name = icon_child.get_string ();

		medias = {};
		for (int i = 0; i < medias_child.n_children (); i++) {
			var media = medias_child.get_child_value (i);
			medias += new Media.parse (media);
		}
	}

	public void add_media (Media media) {
		medias += media;
	}

	public int get_size () {
		return medias.length;
	}

	public Media get_selected_media (uint index) throws Error {
		return get_media (selected_media_number);
	}

	public void foreach_media (MediaCallback media_callback) {
		foreach (var media in medias)
			media_callback (media);
	}

	private Media get_media (uint index) throws Error {
		if (index >= medias.length)
			throw new MediaSetError.NOT_A_MEDIA (_("Invalid media index %u."), index);

		return medias[index];
	}

	public Variant serialize () {
		Variant[] media_variants = {};
		foreach_media (media => {
			media_variants += media.serialize ();
		});

		return new Variant.tuple ({
			new Variant.string (icon_name),
			new Variant.array (Media.get_variant_type (), media_variants)
		});
	}

	public static VariantType get_variant_type () {
		return new VariantType.tuple ({
			VariantType.STRING,
			new VariantType.array (Media.get_variant_type ())
		});
	}
}
