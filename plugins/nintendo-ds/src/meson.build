vala_sources = [
  'nintendo-ds-icon.vala',
  'nintendo-ds-layout.vala',
  'nintendo-ds-layout-item.vala',
  'nintendo-ds-layout-switcher.vala',
  'nintendo-ds-plugin.vala',
  'nintendo-ds-runner.vala',
]

c_sources = [
  'nintendo-ds-icon-extract.c',
]

c_args = [
  '-DG_LOG_DOMAIN="GamesNintendoDS"'
]

shared_module (
  'games-' + plugin_name + '-plugin',
  vala_sources + c_sources + nintendo_ds_resources,
  dependencies: gnome_games_dep,
  c_args: c_args,
  install: true,
  install_dir: plugins_dir
)
