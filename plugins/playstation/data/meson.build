install_data (plugin_name + '.plugin', install_dir: plugins_dir)

sed = find_program ('sed')

# TODO Game titles in the gameinfo file are meant to be localized
gameinfo = custom_target (
  'playstation.gameinfo',
  output: 'playstation.gameinfo.xml',
  input: 'playstation.gameinfo.xml.in',
  command: [sed, '-e', 's|<_title>|<title>|g;s|</_title>|</title>|g', '@INPUT@'],
  capture: true
)

playstation_resources = gnome.compile_resources (
  'org.gnome.Games.plugin.playstation',
  'org.gnome.Games.plugin.playstation.gresource.xml',
  c_name: 'resources',
  dependencies: gameinfo
)
