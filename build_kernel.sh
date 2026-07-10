#!/bin/bash -e

nc=$(nproc)

variations="no-preemptirq preemptirq no-preemptirq-rt preemptirq-rt"

for i in $variations; do
    make "O=build/$i" olddefconfig
    make "O=build/$i" "-j$nc"
    make "O=build/$i" "-j$nc" modules_install
done
