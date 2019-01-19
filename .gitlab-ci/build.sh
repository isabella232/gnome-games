#!/bin/bash

meson _build
ninja -C _build
ninja -C _build test
