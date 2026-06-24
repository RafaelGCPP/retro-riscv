FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y ca-certificates openssl
RUN update-ca-certificates

RUN apt-get install -y --no-install-recommends \
    build-essential

RUN apt-get install -y --no-install-recommends \
    git \
    make \
    cmake \
    ninja-build

RUN apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv

RUN apt-get install -y --no-install-recommends \
    gdb-multiarch \
    qemu-system-misc \
    qemu-system-riscv \
    device-tree-compiler

RUN apt-get install -y --no-install-recommends \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf

RUN apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    file \
    xz-utils \
    unzip \
    less \
    vim \
    nano

RUN apt-get install -y --no-install-recommends \
    verilator

WORKDIR /rv32-bios
