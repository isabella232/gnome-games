plugins = [
  'desktop',
  'dreamcast',
  'game-cube',
  'libretro',
  'love',
  'mame',
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
