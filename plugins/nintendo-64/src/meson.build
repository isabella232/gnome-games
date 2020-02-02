vala_sources = [
  'nintendo-64-pak.vala',
  'nintendo-64-pak-player.vala',
  'nintendo-64-pak-switcher.vala',
  'nintendo-64-platform.vala',
  'nintendo-64-plugin.vala',
  'nintendo-64-runner.vala',
  'nintendo-64-savestate.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesNintendo64"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + nintendo_64_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
