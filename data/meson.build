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
      'validate-relax', appdata_file.full_path()
    ]
  )
endif

gsettings_conf = configuration_data ()
gsettings_conf.set ('GETTEXT_PACKAGE', meson.project_name ())
configure_file (
  input: 'org.gnome.Games.gschema.xml',
  output: 'org.gnome.Games.gschema.xml',
  configuration: gsettings_conf,
  install: true,
  install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)

ontology_conf = configuration_data()
ontology_conf.set('appid', application_id)
configure_file (
  input: 'org.gnome.Games.rule.in',
  output: '@0@.rule'.format(application_id),
  configuration: ontology_conf,
  install: true,
  install_dir: join_paths (datadir, 'tracker', 'domain-ontologies')
)

service_conf = configuration_data()
service_conf.set('appid', application_id)
service_conf.set('libexecdir', libexecdir)

services = [
  'Tracker1',
  'Tracker1.Miner.Applications',
  'Tracker1.Miner.Extract',
  'Tracker1.Miner.Files',
  'Tracker1.Writeback',
]

foreach service: services
  configure_file (
    input: 'org.gnome.Games.@0@.service.in'.format(service),
    output: '@0@.@1@.service'.format(application_id, service),
    configuration: service_conf,
    install: true,
    install_dir: join_paths (datadir, 'dbus-1', 'services')
  )
endforeach

subdir ('icons')
subdir ('options')
