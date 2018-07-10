vala_sources = [
  'steam-cover.vala',
  'steam-error.vala',
  'steam-icon.vala',
  'steam-plugin.vala',
  'steam-registry.vala',
  'steam-title.vala',
  'steam-uri-iterator.vala',
  'steam-uri-source.vala',
  'steam-uid.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesSteam"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
