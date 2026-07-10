#!/bin/bash -e

git checkout origin/os-build
make dist-configs
make mrproper
git checkout preemptirq

kernel_version=$(find redhat/configs/ -name 'kernel-*-x86_64.config' | head -1 | xargs basename | sed -e 's/kernel-\([^-]\+\)-x86_64.config/\1/')

declare -A config_files=(
    [no-preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [no-preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
)

declare -A extra_configs=(
    [no-preemptirq]="CONFIG_BPF_SYSCALL"
    [preemptirq]="CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMP_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE"
    [no-preemptirq-rt]="CONFIG_BPF_SYSCALL"
    [preemptirq-rt]="CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMP_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE"
)

if ! test -d build/; then
    mkdir build
    for k in "${!config_files[@]}"; do
        mkdir build/"$k"
    done
fi

for k in "${!config_files[@]}"; do
    cp "${config_files[$k]}" build/"$k"/.config
    ./scripts/config --file "build/$k/.config" --set-str CONFIG_LOCALVERSION "-$k"
    for c in ${extra_configs[$k]}; do
        ./scripts/config --file "build/$k/.config" --enable "$c"
    done
done

