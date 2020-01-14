hicolor_dir = join_paths(datadir, 'icons', 'hicolor')

scalable_dir = join_paths('scalable', 'apps')
install_data(
  join_paths(scalable_dir, '@0@.svg'.format(application_id)),
  install_dir: join_paths(hicolor_dir, scalable_dir)
)

symbolic_dir = join_paths('symbolic', 'apps')
install_data(
  join_paths(symbolic_dir, 'org.gnome.Games-symbolic.svg'),
  install_dir: join_paths(hicolor_dir, symbolic_dir),
  rename: '@0@-symbolic.svg'.format(application_id)
)
