install_data (plugin_name + '.plugin', install_dir: plugins_dir)

nintendo_ds_resources = gnome.compile_resources (
  'nintendo-ds',
  'nintendo-ds.gresource.xml',
  c_name: 'resources'
)

configure_file (
  input: 'org.gnome.Games.plugins.nintendo-ds.gschema.xml',
  output: 'org.gnome.Games.plugins.nintendo-ds.gschema.xml',
  configuration: gsettings_conf,
  install: true,
  install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
)
