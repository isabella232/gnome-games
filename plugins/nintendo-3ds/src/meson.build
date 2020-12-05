vala_sources = [
  'nintendo-3ds-layout.vala',
  'nintendo-3ds-plugin.vala',
  'nintendo-3ds-runner.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesNintendo3DS"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
