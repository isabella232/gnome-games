plugindir = $(libdir)/gnome-games/plugins
plugin_LTLIBRARIES = libgames-virtual-boy-plugin.la

libgames_virtual_boy_plugin_la_DEPENDENCIES = \
	$(top_builddir)/src/gnome-games.vapi \
	$(NULL)

libgames_virtual_boy_plugin_la_SOURCES = \
	virtual-boy-header.vala \
	virtual-boy-plugin.vala \
	$(NULL)

libgames_virtual_boy_plugin_la_VALAFLAGS = \
	--target-glib=@GLIB_MIN_VERSION@ \
	--pkg gnome-games \
	--vapidir $(top_builddir)/src \
	$(NULL)

libgames_virtual_boy_plugin_la_CFLAGS = \
	$(VIRTUAL_BOY_PLUGIN_CFLAGS) \
	$(GNOME_GAMES_CFLAGS) \
	-DRETRO_GTK_USE_UNSTABLE_API \
	-DG_LOG_DOMAIN=\"GamesVirtualBoy\" \
	-DLOCALEDIR=\"$(localedir)\" \
	$(NULL)

libgames_virtual_boy_plugin_la_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/src \
	$(NULL)

libgames_virtual_boy_plugin_la_LIBADD = \
	$(VIRTUAL_BOY_PLUGIN_LIBS) \
	$(GNOME_GAMES_LIBS) \
	$(NULL)

libgames_virtual_boy_plugin_la_LDFLAGS = \
	-no-undefined \
	-module \
	-avoid-version \
	$(NULL)

EXTRA_DIST = \
	$(plugin_DATA) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)

-include $(top_srcdir)/git.mk
