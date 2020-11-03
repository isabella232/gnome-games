vala_sources = [
  'dreamcast-error.vala',
  'dreamcast-header.vala',
  'dreamcast-plugin.vala',

  'gdi/gdi.vala',
  'gdi/gdi-error.vala',
  'gdi/gdi-track-node.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesDreamcast"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
