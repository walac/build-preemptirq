# build-preemptirq

Container image and helper scripts for building and benchmarking a Linux
kernel with a "preemptirq" tracing feature, across four config variants:

- `no-preemptirq` — baseline kernel
- `preemptirq` — baseline kernel + preemptirq feature
- `no-preemptirq-rt` — RT kernel
- `preemptirq-rt` — RT kernel + preemptirq feature

The scripts assume they are run **inside a RHEL/CentOS Stream-style kernel
git tree** (one with `os-build` and `preemptirq` branches, and a
`redhat/configs/` directory with `make dist-configs`/`make dist-...`
support), not inside this repo.

## Files

- `Containerfile` — Fedora 44 image with the kernel build toolchain
  (gcc/make, clang/llvm, bpftool, libbpf-devel, dwarves, bc, openssl) plus
  `build_kernel.sh` and `build_tracebench.sh` installed to `/usr/bin`.
- `kernel_init_build.sh` — generates the four `build/<variant>/.config`
  files from the kernel tree's dist configs (regular config for the two
  non-RT variants, `-rt` config for the two RT variants), tags each with a
  distinct `CONFIG_LOCALVERSION`, and enables the extra options each
  variant needs (`CONFIG_BPF_SYSCALL` for all four; `CONFIG_TRACE_PREEMP_TOGGLE`
  and `CONFIG_TRACE_IRQFLAGS_TOGGLE` additionally for the two variants with
  the preemptirq feature).
- `build_kernel.sh` — runs `olddefconfig`, builds, and `modules_install`
  for each of the four `build/<variant>` output directories.
- `build_tracebench.sh` — builds and installs the out-of-tree `tracebench`
  module against every installed kernel found under `/lib/modules/7*`
  (i.e. against each of the four variants built above).

## Usage

Build the container image:

```sh
podman build -t build-preemptirq .
```

Run in the host kernel tree:

```sh
./kernel_init_build.sh   # prepare build/<variant>/.config for all 4 variants
```

Run it with the kernel source tree mounted at `/src`:

```sh
podman run --rm -it -v /path/to/kernel:/src/linux -v /path/to/tracer-benchmark:/src/tracer-benchmark --security-opt label=disable build-preemptirq
```

Inside the container, from the kernel tree:

```sh
build_kernel.sh          # build and install all 4 kernel variants
```

Then, from the `tracebench` module's source directory (with all four
kernels installed on the system):

```sh
build_tracebench.sh      # build and install the module against each kernel
```
