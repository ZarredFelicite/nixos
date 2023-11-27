project('iio-hyprland', 'c',
	license: 'GPL3',
	default_options: ['buildtype=release','warning_level=3', 'optimization=3'])
dbus = dependency('dbus-1')
executable('iio-hyprland', ['main.c'], dependencies: [dbus], install : true)
