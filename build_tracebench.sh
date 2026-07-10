#!/bin/bash -e

for i in /lib/modules/7*; do
    make -C "$i/build" M="$PWD" clean
    make -C "$i/build" M="$PWD" modules
    make -C "$i/build" M="$PWD" modules_install
done
