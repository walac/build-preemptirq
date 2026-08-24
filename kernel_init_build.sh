#!/bin/bash -e

git checkout origin/os-build
make dist-configs
make mrproper
git checkout preemptirq

kernel_version=$(find redhat/configs/ -name 'kernel-*-x86_64.config' | head -1 | xargs basename | sed -e 's/kernel-\([^-]\+\)-x86_64.config/\1/')

declare -A config_files=(
    [no-preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [tracer]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [no-preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [tracer-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
)

declare -A extra_configs=(
    [no-preemptirq]="CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES"
    [preemptirq]="CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMPT_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES"
    [tracer]="CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_PREEMPT_TRACER CONFIG_IRQSOFF_TRACER"
    [no-preemptirq-rt]="CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES"
    [preemptirq-rt]="CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMPT_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES"
    [tracer-rt]="CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_PREEMPT_TRACER CONFIG_IRQSOFF_TRACER"
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
    ./scripts/config --file "build/$k/.config" --disable CONFIG_DEBUG_PREEMPT
done

