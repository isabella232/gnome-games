vala_sources = [
  'libretro-error.vala',
  'libretro-icon.vala',
  'libretro-plugin.vala',
  'libretro-title.vala',
  'libretro-uid.vala',
  'libretro-uri-iterator.vala',
  'libretro-uri-source.vala',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesLibretro"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
