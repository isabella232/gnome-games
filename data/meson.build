resources = gnome.compile_resources(
  'org.gnome.Games',
  'org.gnome.Games.gresource.xml',
  c_name: 'resources'
)

desktop_conf = configuration_data()
desktop_conf.set('icon', application_id)
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
  install_dir: join_paths (datadir, 'applications')
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
  install_dir: join_paths (datadir, 'metainfo')
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
  install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

search_provider_conf = configuration_data()
search_provider_conf.set('appid', application_id)
search_provider_conf.set('profile', profile)
configure_file(
  configuration: search_provider_conf,
  input: 'org.gnome.Games.SearchProvider.ini.in',
  install_dir: join_paths(datadir, 'gnome-shell', 'search-providers'),
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
