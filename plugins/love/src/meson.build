vala_sources = [
  'love-error.vala',
  'love-icon.vala',
  'love-package.vala',
  'love-plugin.vala',
  'love-title.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesLOVE"'
]

libarchive_dep = dependency ('libarchive')

dependencies = [
  gnome_games_dep,
  libarchive_dep,
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: dependencies,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
