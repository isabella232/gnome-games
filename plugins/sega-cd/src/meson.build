vala_sources = [
  'sega-cd-header.vala',
  'sega-cd-plugin.vala',
  'sega-cd-system.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesSegaCD"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
