vala_sources = [
  'turbografx-cd-error.vala',
  'turbografx-cd-plugin.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesTurboGrafxCD"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
