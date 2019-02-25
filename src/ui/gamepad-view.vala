// This file is part of GNOME Games. License: GPL-3.0+.

private class Games.GamepadView : Gtk.DrawingArea {
	private Rsvg.Handle handle;
	private bool[] input_highlights;

	private GamepadViewConfiguration _configuration;
	public GamepadViewConfiguration configuration {
		get { return _configuration; }
		set {
			if (value == configuration)
				return;

			try {
				var bytes = resources_lookup_data (value.svg_path, ResourceLookupFlags.NONE);
				var data = bytes.get_data ();

				handle = new Rsvg.Handle.from_data (data);
			}
			catch (Error e) {
				critical ("Could not set up gamepad view: %s", e.message);
			}

			set_size_request (handle.width, handle.height);
			_configuration = value;
			input_highlights = new bool[value.input_paths.length];

			reset ();
		}
	}

	construct {
		handle = new Rsvg.Handle ();
		configuration = { "", new GamepadInputPath[0] };
		input_highlights = {};
	}

	public void reset () {
		for (var i = 0; i < input_highlights.length; ++i)
			input_highlights[i] = false;

		queue_draw ();
	}

	public bool highlight (GamepadInput input, bool highlight) {
		for (var i = 0; i < configuration.input_paths.length; ++i) {
			if (configuration.input_paths[i].input == input) {
				input_highlights[i] = highlight;
				queue_draw ();

				return true;
			}
		}

		return false;
	}

	public override bool draw (Cairo.Context context) {
		double x, y, scale;
		calculate_image_dimensions (out x, out y, out scale);

		context.translate (x, y);
		context.scale (scale, scale);

		color_gamepad (context);
		highlight_gamepad (context);

		return false;
	}

	private void color_gamepad (Cairo.Context context) {
		context.push_group ();
		handle.render_cairo (context);
		var group = context.pop_group ();

		Gdk.RGBA color;
		get_style_context ().lookup_color ("theme_fg_color", out color);
		context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
		context.mask (group);
	}

	private void highlight_gamepad (Cairo.Context context) {
		for (var i = 0; i < configuration.input_paths.length; ++i)
			if (input_highlights[i]) {
				context.push_group ();
				handle.render_cairo_sub (context, "#" + configuration.input_paths[i].path);
				var group = context.pop_group ();

				Gdk.RGBA color;
				get_style_context ().lookup_color ("theme_selected_bg_color", out color);
				context.set_source_rgba (color.red, color.green, color.blue, color.alpha);
				context.mask (group);
			}
	}

	private void calculate_image_dimensions (out double x, out double y, out double scale) {
		double w = get_allocated_width ();
		double h = get_allocated_height ();

		scale = double.min (h / handle.height, w / handle.width);

		x = (w - handle.width * scale) / 2;
		y = (h - handle.height * scale) / 2;
	}
}
