#!/bin/bash

# Build libmanette
git clone --depth 1 https://gitlab.gnome.org/aplazas/libmanette.git
cd libmanette
meson --prefix=/usr _build
ninja -C _build install
cd ..

# Build retro-gtk
git clone --depth 1 https://gitlab.gnome.org/GNOME/retro-gtk.git
cd retro-gtk
meson --prefix=/usr _build
ninja -C _build install
cd ..
