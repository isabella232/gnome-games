plugins = [
  'desktop',
  'dreamcast',
  'game-cube',
  'libretro',
  'love',
  'mame',
  'ms-dos',
  'nintendo-3ds',
  'nintendo-64',
  'nintendo-ds',
  'playstation',
  'sega-cd',
  'sega-saturn',
  'steam',
  'turbografx-cd',
  'virtual-boy',
  'wii',
]

foreach plugin_name : plugins
  if get_option (plugin_name +'-plugin')
    subdir (plugin_name)
  endif
endforeach
