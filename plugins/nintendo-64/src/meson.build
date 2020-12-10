vala_sources = [
  'nintendo-64-pak.vala',
  'nintendo-64-pak-controller.vala',
  'nintendo-64-pak-switcher.vala',
  'nintendo-64-platform.vala',
  'nintendo-64-plugin.vala',
  'nintendo-64-runner.vala',
  'nintendo-64-snapshot.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesNintendo64"'
]

nintendo_64_resources = gnome.compile_resources (
  'nintendo-64',
  'nintendo-64.gresource.xml',
  c_name: 'resources'
)

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + nintendo_64_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
