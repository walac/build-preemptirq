FROM fedora:44

# Standard Fedora kernel build toolchain (Fedora "Building a custom kernel"
# wiki + Documentation/process/changes.rst minimal requirements), plus git
# and rsync/cpio which build_kernel.sh and kernel install scripts rely on
# but aren't strict compile-time requirements.
RUN dnf upgrade -y --refresh
RUN dnf group install -y development-tools
RUN dnf group install -y c-development
RUN dnf install -y clang llvm-devel bpftool \
        libbpf-devel vim dwarves bash-completion \
        bc openssl openssl-devel

COPY build_kernel.sh /usr/bin/
COPY build_tracebench.sh /usr/bin/

WORKDIR /src

CMD ["/bin/bash"]
