vala_sources = [
  'virtual-boy-header.vala',
  'virtual-boy-plugin.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesVirtualBoy"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
