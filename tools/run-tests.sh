#!/bin/bash

WORK_DIR="unit-tests"
MANIFEST_PATH="../../flatpak/org.gnome.Games.UnitTests.yml"
FLATPAK_MODULE="retro-gtk"
FLATPAK_BUILD_DIR="unit-tests"
MESON_ARGS="--libdir=lib -Dinstall-tests=true"

mkdir -p $WORK_DIR
cd $WORK_DIR

rm -rf ${FLATPAK_BUILD_DIR}
flatpak-builder --repo=repo ${FLATPAK_BUILD_DIR} ${MANIFEST_PATH}

if [[ -z "${DISPLAY}" ]]; then
    xvfb-run -a -s "-screen 0 1024x768x24" flatpak-builder --run ${FLATPAK_BUILD_DIR} ${MANIFEST_PATH} games-unit-tests
else
    flatpak-builder --run ${FLATPAK_BUILD_DIR} ${MANIFEST_PATH} games-unit-tests
fi
