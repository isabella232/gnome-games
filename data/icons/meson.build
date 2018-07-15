icon_sizes = ['16x16', '22x22', '24x24', '32x32', '48x48', '256x256', '512x512']

foreach icon_size: icon_sizes
  hicolor_dir = join_paths('hicolor', icon_size, 'apps')
  highcontrast_dir = join_paths('HighContrast', icon_size, 'apps')

  install_data(
    join_paths(hicolor_dir, 'org.gnome.Games.png'),
    install_dir: join_paths(datadir, 'icons', hicolor_dir),
    rename: '@0@.png'.format(application_id)
  )

  install_data(
    join_paths(highcontrast_dir, 'org.gnome.Games.png'),
    install_dir: join_paths(datadir, 'icons', highcontrast_dir),
    rename: '@0@.png'.format(application_id)
  )
endforeach

hicolor_dir = join_paths('hicolor', 'scalable', 'apps')

install_data(
  join_paths(hicolor_dir, 'org.gnome.Games-symbolic.svg'),
  install_dir: join_paths(datadir, 'icons', hicolor_dir),
  rename: '@0@-symbolic.svg'.format(application_id)
)
