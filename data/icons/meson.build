hicolor_dir = datadir / 'icons' / 'hicolor'

scalable_dir = 'scalable' / 'apps'
install_data(
  scalable_dir / '@0@.svg'.format(application_id),
  install_dir: hicolor_dir / scalable_dir
)

symbolic_dir = 'symbolic' / 'apps'
install_data(
  symbolic_dir / 'org.gnome.Games-symbolic.svg',
  install_dir: hicolor_dir / symbolic_dir,
  rename: '@0@-symbolic.svg'.format(application_id)
)
