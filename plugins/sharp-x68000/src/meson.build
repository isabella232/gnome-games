vala_sources = [
  'sharp-x68000-game-factory.vala',
  'sharp-x68000-plugin.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesSharpX68000"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
