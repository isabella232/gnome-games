vala_sources = [
  'mame-error.vala',
  'mame-game-info.vala',
  'mame-game-uri-adapter.vala',
  'mame-plugin.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesMAME"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + mame_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
