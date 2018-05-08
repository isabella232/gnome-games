PKG_CHECK_MODULES(VIRTUAL_BOY_PLUGIN, [
	gio-2.0
	glib-2.0 >= $GLIB_MIN_VERSION
	gtk+-3.0
	retro-gtk-0.14
], [enable_virtual_boy_plugin=yes], [enable_virtual_boy_plugin=no])

AM_CONDITIONAL(ENABLE_VIRTUAL_BOY_PLUGIN, test x$enable_virtual_boy_plugin != xno)

AC_CONFIG_FILES([
	plugins/virtual-boy/Makefile
	plugins/virtual-boy/data/Makefile
	plugins/virtual-boy/src/Makefile
])
