#!/bin/bash -e

git checkout origin/os-build
make dist-configs
make mrproper
git checkout preemptirq

kernel_version=$(find redhat/configs/ -name 'kernel-*-x86_64.config' | head -1 | xargs basename | sed -e 's/kernel-\([^-]\+\)-x86_64.config/\1/')

declare -A config_files=(
    [no-preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [preemptirq]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [tracer]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [dbg-preempt]="redhat/configs/kernel-$kernel_version-x86_64.config"
    [no-preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [preemptirq-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [tracer-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
    [dbg-preempt-rt]="redhat/configs/kernel-$kernel_version-x86_64-rt.config"
)

declare -A extra_configs=(
    [no-preemptirq]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES !CONFIG_DEBUG_PREEMPT"
    [preemptirq]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMPT_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES !CONFIG_DEBUG_PREEMPT"
    [tracer]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_PREEMPT_TRACER CONFIG_IRQSOFF_TRACER !CONFIG_DEBUG_PREEMPT"
    [dbg-preempt]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_DEBUG_PREEMPT"
    [no-preemptirq-rt]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES !CONFIG_DEBUG_PREEMPT CONFIG_PREEMPT_RT"
    [preemptirq-rt]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_TRACE_PREEMPT_TOGGLE CONFIG_TRACE_IRQFLAGS_TOGGLE CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES !CONFIG_DEBUG_PREEMPT CONFIG_PREEMPT_RT"
    [tracer-rt]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_PREEMPT_TRACER CONFIG_IRQSOFF_TRACER !CONFIG_DEBUG_PREEMPT CONFIG_PREEMPT_RT"
    [dbg-preempt-rt]="CONFIG_EXPERT CONFIG_BPF_SYSCALL CONFIG_DEBUG_INFO_BTF CONFIG_DEBUG_INFO_BTF_MODULES CONFIG_DEBUG_PREEMPT CONFIG_PREEMPT_RT"
)

for k in "${!config_files[@]}"; do
    mkdir -p build/"$k"
    cp "${config_files[$k]}" build/"$k"/.config
    ./scripts/config --file "build/$k/.config" --set-str CONFIG_LOCALVERSION "-$k"
    # Configs prefixed with ! are disabled; others are enabled
    for c in ${extra_configs[$k]}; do
        if [[ "$c" == !* ]]; then
            ./scripts/config --file "build/$k/.config" --disable "${c#!}"
        else
            ./scripts/config --file "build/$k/.config" --enable "$c"
        fi
    done
done

