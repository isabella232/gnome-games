vala_sources = [
  'playstation-error.vala',
  'playstation-game-factory.vala',
  'playstation-header.vala',
  'playstation-plugin.vala',
]

c_sources = [
  'disc-file-info.c',
  'disc-image.c',
  'disc-image-time.c',
  'playstation-disc-image.c',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesPlayStation"'
]

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

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + c_sources + playstation_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
