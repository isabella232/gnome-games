resources = gnome.compile_resources(
  'org.gnome.Games',
  'org.gnome.Games.gresource.xml',
  c_name: 'resources'
)

desktop_conf = configuration_data()
desktop_conf.set('icon', application_id)
i18n.merge_file ('desktop-file',
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

appdata_conf = configuration_data()
appdata_conf.set('appid', application_id)
i18n.merge_file ('appdata-file',
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

gsettings_conf = configuration_data ()
gsettings_conf.set ('GETTEXT_PACKAGE', meson.project_name ())
configure_file (
  input: 'org.gnome.Games.gschema.xml',
  output: 'org.gnome.Games.gschema.xml',
  configuration: gsettings_conf,
  install: true,
  install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

subdir ('icons')
subdir ('options')
