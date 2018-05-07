vala_sources = [
  'game-cube-header.vala',
  'game-cube-plugin.vala',
  'game-cube-uid.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesGameCube"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
