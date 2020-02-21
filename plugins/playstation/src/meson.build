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

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + c_sources + playstation_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
