#!/bin/bash

# Build libhandy
git clone --depth 1 https://source.puri.sm/Librem5/libhandy.git
cd libhandy
meson --prefix=/usr -Dtests=false -Dexamples=false -Dglade_catalog=disabled _build
ninja -C _build install
cd ..

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
