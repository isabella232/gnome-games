AC_INIT([gnome-games], [3.29.1])
AM_INIT_AUTOMAKE([foreign subdir-objects tar-ustar no-dist-gzip dist-xz])

# i18 support
IT_PROG_INTLTOOL(0.40.0)
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

AC_PROG_CC
AM_PROG_VALAC

# GResource
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

# GSettings support
GLIB_GSETTINGS

GLIB_MIN_VERSION=2.38.0
MANETTE_MIN_VERSION=0.2.0
RETRO_GTK_MIN_VERSION=0.13.2
AC_SUBST(GLIB_MIN_VERSION)
AC_SUBST(MANETTE_MIN_VERSION)
AC_SUBST(RETRO_GTK_MIN_VERSION)

LT_INIT

# Plugins
m4_include([plugins/desktop/configure.ac])
m4_include([plugins/dreamcast/configure.ac])
m4_include([plugins/game-cube/configure.ac])
m4_include([plugins/libretro/configure.ac])
m4_include([plugins/love/configure.ac])
m4_include([plugins/mame/configure.ac])
m4_include([plugins/nintendo-ds/configure.ac])
m4_include([plugins/playstation/configure.ac])
m4_include([plugins/sega-cd/configure.ac])
m4_include([plugins/sega-saturn/configure.ac])
m4_include([plugins/steam/configure.ac])
m4_include([plugins/turbografx-cd/configure.ac])
m4_include([plugins/virtual-boy/configure.ac])
m4_include([plugins/wii/configure.ac])

PKG_CHECK_MODULES(GNOME_GAMES, [
	gio-2.0
	glib-2.0 >= $GLIB_MIN_VERSION
	grilo-0.3
	gtk+-3.0
	manette-0.2 >= $MANETTE_MIN_VERSION
	librsvg-2.0
	libsoup-2.4
	libxml-2.0
	retro-gtk-0.14 >= $RETRO_GTK_MIN_VERSION
	sqlite3
	tracker-sparql-2.0
])

AC_CONFIG_FILES([
	Makefile
	data/Makefile
	data/icons/Makefile
	data/options/Makefile
	plugins/Makefile
	po/Makefile.in
	src/Makefile
])

AC_OUTPUT
