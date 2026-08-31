#!/bin/bash -e

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

if ! "$use_vng"; then
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

fi

declare -A extra_configs=(
    [no-preemptirq]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES !DEBUG_PREEMPT"
    [preemptirq]="EXPERT BPF_SYSCALL TRACE_PREEMPT_TOGGLE TRACE_IRQFLAGS_TOGGLE DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES !DEBUG_PREEMPT"
    [tracer]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES PREEMPT_TRACER IRQSOFF_TRACER !DEBUG_PREEMPT"
    [dbg-preempt]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES DEBUG_PREEMPT"
    [no-preemptirq-rt]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES !DEBUG_PREEMPT PREEMPT_RT"
    [preemptirq-rt]="EXPERT BPF_SYSCALL TRACE_PREEMPT_TOGGLE TRACE_IRQFLAGS_TOGGLE DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES !DEBUG_PREEMPT PREEMPT_RT"
    [tracer-rt]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES PREEMPT_TRACER IRQSOFF_TRACER !DEBUG_PREEMPT PREEMPT_RT"
    [dbg-preempt-rt]="EXPERT BPF_SYSCALL DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES DEBUG_PREEMPT PREEMPT_RT"
)

for k in "${!extra_configs[@]}"; do
    mkdir -p build/"$k"
    if "$use_vng"; then
        KBUILD_OUTPUT=build/"$k" vng -k
    else
        cp "${config_files[$k]}" build/"$k"/.config
    fi
    ./scripts/config --file "build/$k/.config" --set-str LOCALVERSION "-$k"
    # Configs prefixed with ! are disabled; others are enabled
    for c in ${extra_configs[$k]}; do
        if [[ "$c" == !* ]]; then
            ./scripts/config --file "build/$k/.config" --disable "${c#!}"
        else
            ./scripts/config --file "build/$k/.config" --enable "$c"
        fi
    done
done
