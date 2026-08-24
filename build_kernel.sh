#!/bin/bash -e

nc=$(nproc)

for i in build/*; do
    config=$(basename "$i")
    make "O=build/$config" olddefconfig
    make "O=build/$config" "-j$nc"
    make "O=build/$config" "-j$nc" modules_install
done
