mime_types = [
  'application/vnd.nintendo.snes.rom',
  'application/x-amiga-disk-format',
  'application/x-atari-2600-rom',
  'application/x-atari-7800-rom',
  'application/x-atari-lynx-rom',
  'application/x-cue',
  'application/x-discjuggler-cd-image',
  'application/x-doom-wad',
  'application/x-fds-disk',
  'application/x-gameboy-color-rom',
  'application/x-gameboy-rom',
  'application/x-gamecube-rom',
  'application/x-gamegear-rom',
  'application/x-gba-rom',
  'application/x-gd-rom-cue',
  'application/x-genesis-32x-rom',
  'application/x-genesis-rom',
  'application/x-love-game',
  'application/x-mame-rom',
  'application/x-ms-dos-executable',
  'application/x-n64-rom',
  'application/x-neo-geo-pocket-color-rom',
  'application/x-neo-geo-pocket-rom',
  'application/x-nes-rom',
  'application/x-nintendo-3ds-executable',
  'application/x-nintendo-3ds-rom',
  'application/x-nintendo-ds-rom',
  'application/x-pc-engine-rom',
  'application/x-playstation-rom',
  'application/x-saturn-rom',
  'application/x-sega-cd-rom',
  'application/x-sega-pico-rom',
  'application/x-sg1000-rom',
  'application/x-sms-rom',
  'application/x-virtual-boy-rom',
  'application/x-wii-rom',
  'application/x-wii-wad',
  'application/x-wonderswan-color-rom',
  'application/x-wonderswan-rom',
  'application/zip',
]

desktop_conf = configuration_data()
desktop_conf.set('icon', application_id)
desktop_conf.set('mimetypes', ';'.join(mime_types) + ';')
desktop_file = i18n.merge_file ('desktop-file',
  type: 'desktop',
  input: configure_file(
    input: files('org.gnome.Games.desktop.in.in'),
    output: 'org.gnome.Games.desktop.in',
    configuration: desktop_conf
  ),
  output: '@0@.desktop'.format(application_id),
  po_dir: podir,
  install: true,
  install_dir: datadir / 'applications'
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

appdata_conf = configuration_data()
appdata_conf.set('appid', application_id)
appdata_file = i18n.merge_file ('appdata-file',
  input: configure_file(
    input: files('org.gnome.Games.appdata.xml.in.in'),
    output: 'org.gnome.Games.appdata.xml.in',
    configuration: appdata_conf
  ),
  output: '@0@.appdata.xml'.format(application_id),
  po_dir: podir,
  install: true,
  install_dir: datadir / 'metainfo'
)

appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test(
    'validate-appdata', appstream_util,
    args: [
      'validate-strict', '--nonet', appdata_file.full_path()
    ]
  )
endif

dbus_conf = configuration_data()
dbus_conf.set('appid', application_id)
dbus_conf.set('bindir', bindir)
configure_file (
  input: 'org.gnome.Games.service.in',
  output: '@0@.service'.format(application_id),
  configuration: dbus_conf,
  install: true,
  install_dir: servicedir
)

gsettings_conf = configuration_data ()
gsettings_conf.set ('GETTEXT_PACKAGE', meson.project_name ())
configure_file (
  input: 'org.gnome.Games.gschema.xml',
  output: 'org.gnome.Games.gschema.xml',
  configuration: gsettings_conf,
  install: true,
  install_dir: datadir / 'glib-2.0' / 'schemas',
)

search_provider_conf = configuration_data()
search_provider_conf.set('appid', application_id)
search_provider_conf.set('profile', profile)
configure_file(
  configuration: search_provider_conf,
  input: 'org.gnome.Games.SearchProvider.ini.in',
  install_dir: datadir / 'gnome-shell' / 'search-providers',
  install: true,
  output: '@0@.SearchProvider.ini'.format(application_id)
)

search_provider_dbus_conf = configuration_data()
search_provider_dbus_conf.set('appid', application_id)
search_provider_dbus_conf.set('libexecdir', libexecdir)
configure_file (
  input: 'org.gnome.Games.SearchProvider.service.in',
  output: '@0@.SearchProvider.service'.format(application_id),
  configuration: search_provider_dbus_conf,
  install: true,
  install_dir: servicedir
)

subdir ('icons')
subdir ('options')
