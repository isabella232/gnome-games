resources = gnome.compile_resources(
  'org.gnome.Games',
  'org.gnome.Games.gresource.xml',
  c_name: 'resources'
)

i18n.merge_file ('desktop-file',
  type: 'desktop',
  input: 'org.gnome.Games.desktop.in',
  output: 'org.gnome.Games.desktop',
  po_dir: podir,
  install: true,
  install_dir: join_paths (datadir, 'applications')
)

i18n.merge_file ('appdata-file',
  input: 'org.gnome.Games.appdata.xml.in',
  output: 'org.gnome.Games.appdata.xml',
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
