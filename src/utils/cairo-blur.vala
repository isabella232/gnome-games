// This file is part of GNOME Games. License: GPL-3.0+.

namespace Games.CairoBlur {
	public void blur_surface (Cairo.Surface surface, float radius) {
		if (surface == null)
			return;

		if (surface.get_type () != Cairo.SurfaceType.IMAGE)
			return;

		var image_surface = (Cairo.ImageSurface) surface;
		var format = image_surface.get_format ();
		if (format != Cairo.Format.RGB24 && format != Cairo.Format.ARGB32)
			return;

		if (radius == 0)
			return;

		/* Before we mess with the surface execute any pending drawing. */
		surface.flush ();
		unowned var data = image_surface.get_data ();
		var width = image_surface.get_width ();
		var height = image_surface.get_height ();
		var stride = image_surface.get_stride ();

		exp_blur (data,
		          width,
		          height,
		          stride,
		          4,
		          radius,
		          16,
		          7);

		/* Inform cairo we altered the surfaces contents. */
		surface.mark_dirty ();
	}

	private void exp_blur (uchar[] pixels, int width, int height,
	                       int rowstride, int channels, float radius,
	                       int aprec, int zprec) {
		/* Calculate the alpha such that 90% of
		*  the kernel is within the radius.
		*  (Kernel extends to infinity) */
		var alpha = (int) ((1 << aprec) * (1.0f - Math.expf (-2.3f / (radius + 1.0f))));

		for (int row = 0; row < height; row++)
			blur_row (pixels, width, height,
			         rowstride, channels, row,
			         alpha, aprec, zprec);

		for(int col = 0; col < width; col++)
			blur_col (pixels, width, height,
			          rowstride, channels, col,
			          alpha, aprec, zprec);
	}

	private void blur_row (uchar[] pixels, int width, int height,
	                       int rowstride, int channels, int line,
	                       int alpha, int aprec, int zprec) {
		var offset = line * rowstride;

		int zR = pixels[offset] << zprec;
		int zG = pixels[offset + 1] << zprec;
		int zB = pixels[offset + 2] << zprec;
		int zA = pixels[offset + 3] << zprec;

		for (int index = 0; index < width; index ++)
			blur_inner (pixels, offset + index * channels,
			            ref zR, ref zG, ref zB, ref zA,
			            alpha, aprec, zprec);

		for (int index = width - 2; index >= 0; index--)
			blur_inner (pixels, offset + index * channels,
			            ref zR, ref zG, ref zB, ref zA,
			            alpha, aprec, zprec);
	}

	private void blur_col (uchar[] pixels, int width, int height,
	                   int rowstride, int channels, int x,
	                   int alpha, int aprec, int zprec) {
		var offset = x * channels;

		int zR = pixels [offset] << zprec;
		int zG = pixels [offset + 1] << zprec;
		int zB = pixels [offset + 2] << zprec;
		int zA = pixels [offset + 3] << zprec;

		for (int index = 0; index < height; index++)
			blur_inner (pixels, offset + index * rowstride,
			            ref zR, ref zG, ref zB, ref zA,
			            alpha, aprec, zprec);

		for (int index = height - 2; index >= 0; index--)
			blur_inner (pixels, offset + index * rowstride,
			            ref zR, ref zG, ref zB, ref zA,
			            alpha, aprec, zprec);
	}

	private void blur_inner (uchar[] pixel, int offset,
	                         ref int zR, ref int zG, ref int zB, ref int zA,
	                         int alpha, int aprec, int zprec) {
		int R = pixel[offset];
		int G = pixel[offset + 1];
		int B = pixel[offset + 2];
		int A = pixel[offset + 3];

		zR += (alpha * ((R << zprec) - zR)) >> aprec;
		zG += (alpha * ((G << zprec) - zG)) >> aprec;
		zB += (alpha * ((B << zprec) - zB)) >> aprec;
		zA += (alpha * ((A << zprec) - zA)) >> aprec;

		pixel[offset]     = (uchar) (zR >> zprec);
		pixel[offset + 1] = (uchar) (zG >> zprec);
		pixel[offset + 2] = (uchar) (zB >> zprec);
		pixel[offset + 3] = (uchar) (zA >> zprec);
	}
}
