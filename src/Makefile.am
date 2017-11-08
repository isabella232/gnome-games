bin_PROGRAMS = gnome-games

gresource_file = $(top_srcdir)/data/org.gnome.Games.gresource.xml

resource_files = $(shell \
	$(GLIB_COMPILE_RESOURCES) \
	--generate-dependencies \
	--sourcedir=$(top_srcdir)/data \
	$(gresource_file) \
)

resources.c: $(gresource_file) $(resource_files)
	$(AM_V_GEN) \
	$(GLIB_COMPILE_RESOURCES) \
		--target=$@ \
		--sourcedir=$(top_srcdir)/data \
		--generate-source \
		$<

BUILT_SOURCES = \
	resources.c \
	$(NULL)

EXTRA_DIST = \
	$(gresource_file) \
	gamepad/event-codes.vapi \
	gamepad/linux/input-event-codes.h \
	$(NULL)

header_file = libgnome-games.h

vapi_file = gnome-games.vapi

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = $(vapi_file)

gnome_games_SOURCES = \
	command/command-error.vala \
	command/command-runner.vala \
	\
	core/cover.vala \
	core/game.vala \
	core/game-callback.vala \
	core/game-collection.vala \
	core/game-uri-adapter.vala \
	core/icon.vala \
	core/input-capabilities.vala \
	core/media.vala \
	core/media-info.vala \
	core/media-set/media-set.vala \
	core/media-set/media-set-error.vala \
	core/plugin.vala \
	core/plugin-register.vala \
	core/plugin-register-iterator.vala \
	core/plugin-registrar.vala \
	core/runner.vala \
	core/title.vala \
	core/uid.vala \
	core/uri-game-factory.vala \
	core/uri-iterator.vala \
	core/uri-source.vala \
	\
	database/database.vala \
	database/database-error.vala \
	database/database-uri-iterator.vala \
	database/database-uri-source.vala \
	\
	dummy/dummy-cover.vala \
	dummy/dummy-game.vala \
	dummy/dummy-icon.vala \
	dummy/dummy-runner.vala \
	\
	gameinfo/gameinfo-doc.vala \
	gameinfo/gameinfo-error.vala \
	gameinfo/gameinfo-disc-id-disc-title.vala \
	gameinfo/gameinfo-disc-id-game-title.vala \
	gameinfo/gameinfo-disc-id-input-capabilities.vala \
	\
	gamepad/gamepad-dpad.vala \
	gamepad/gamepad-input.vala \
	gamepad/gamepad-mapping-builder.vala \
	\
	generic/generic-game.vala \
	generic/generic-game-uri-adapter.vala \
	generic/generic-title.vala \
	generic/generic-uid.vala \
	generic/generic-uri-game-factory.vala \
	\
	grilo/grilo-cover.vala \
	grilo/grilo-media.vala \
	\
	retro/retro-core-source.vala \
	retro/retro-error.vala \
	retro/retro-gamepad.vala \
	retro/retro-input-manager.vala \
	retro/retro-platform.vala \
	retro/retro-runner.vala \
	retro/retro-simple-game-uri-adapter.vala \
	retro/retro-simple-type.vala \
	retro/retro-simple-types.vala \
	\
	tracker/mime-type-tracker-uri-query.vala \
	tracker/tracker-error.vala \
	tracker/tracker-uri-iterator.vala \
	tracker/tracker-uri-query.vala \
	tracker/tracker-uri-source.vala \
	\
	ui/application.vala \
	ui/application-window.vala \
	ui/checkmark-item.vala \
	ui/collection-box.vala \
	ui/collection-icon-view.vala \
	ui/collection-header-bar.vala \
	ui/display-box.vala \
	ui/display-header-bar.vala \
	ui/dummy-display.vala \
	ui/empty-collection.vala \
	ui/error-display.vala \
	ui/error-info-bar.vala \
	ui/gamepad-configurer.vala \
	ui/gamepad-mapper.vala \
	ui/gamepad-tester.vala \
	ui/gamepad-view.vala \
	ui/game-icon-view.vala \
	ui/game-thumbnail.vala \
	ui/gamepad-view-configuration.vala \
	ui/media-selector.vala \
	ui/media-menu-button.vala \
	ui/preferences-page.vala \
	ui/preferences-page-controllers.vala \
	ui/preferences-page-plugins.vala \
	ui/preferences-page-plugins-item.vala \
	ui/preferences-page-video.vala \
	ui/preferences-window.vala \
	ui/quit-dialog.vala \
	ui/remote-display.vala \
	ui/reset-gamepad-mapping-dialog.vala \
	ui/resume-dialog.vala \
	ui/resume-failed-dialog.vala \
	ui/search-bar.vala \
	ui/ui-state.vala \
	\
	utils/composite-cover.vala \
	utils/composite-title.vala \
	utils/cue-sheet/cue-sheet.vala \
	utils/cue-sheet/cue-sheet-error.vala \
	utils/cue-sheet/cue-sheet-file-format.vala \
	utils/cue-sheet/cue-sheet-file-node.vala \
	utils/cue-sheet/cue-sheet-track-mode.vala \
	utils/cue-sheet/cue-sheet-track-node.vala \
	utils/directory.vala \
	utils/filename-title.vala \
	utils/fingerprint.vala \
	utils/grep.vala \
	utils/local-cover.vala \
	utils/string-input-stream.vala \
	utils/uri.vala \
	utils/uri-error.vala \
	utils/xml-doc.vala \
	\
	config.vala \
	credits.vala \
	main.vala \
	$(BUILT_SOURCES) \
	$(NULL)

gnome_games_VALAFLAGS = \
	--target-glib=@GLIB_MIN_VERSION@ \
	--pkg gio-2.0 \
	--pkg glib-2.0 \
	--pkg grilo-0.3 \
	--pkg gtk+-3.0 \
	--pkg libmanette-0.2 \
	--pkg librsvg-2.0 \
	--pkg libsoup-2.4 \
	--pkg libxml-2.0 \
	--pkg sqlite3 \
	--pkg tracker-sparql-2.0 \
	--pkg retro-gtk-0.14 \
	--pkg linux \
	--pkg posix \
	--pkg event-codes \
	--gresources $(gresource_file) \
	--vapi $(vapi_file) \
	--vapidir=gamepad/ \
	-H $(header_file) \
	$(NULL)

gnome_games_CFLAGS = \
	$(GNOME_GAMES_CFLAGS) \
	-I$(srcdir)/gamepad \
	-DGNOMELOCALEDIR=\""$(datadir)/locale"\" \
	-DGAMES_PLUGINS_DIR=\"$(libdir)/gnome-games/plugins\" \
	$(NULL)

gnome_games_CPPFLAGS = \
	-DRETRO_GTK_USE_UNSTABLE_API \
	$(NULL)

gnome_games_LDADD = \
	$(GNOME_GAMES_LIBS) \
	$(NULL)

gnome_gamesincludedir = $(includedir)
gnome_gamesinclude_HEADERS = \
	$(header_file) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(BUILT_SOURCES) \
	$(NULL)

-include $(top_srcdir)/git.mk
