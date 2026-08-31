#!/bin/bash -e

nc=$(nproc)

case "${1:-}" in
    "")
        use_vng=false
        ;;
    --vng)
        use_vng=true
        ;;
    *)
        echo "Usage: $0 [--vng]" >&2
        exit 2
        ;;
esac

for i in build/*; do
    config=$(basename "$i")
    make "O=build/$config" olddefconfig
    make "O=build/$config" "-j$nc"

    if ! "$use_vng"; then
        make O="build/$config" -j"$nc" modules_install
    else
        make O="build/$config" INSTALL_MOD_PATH="build/$config/.mods" -j"$nc" modules_install
    fi
done
