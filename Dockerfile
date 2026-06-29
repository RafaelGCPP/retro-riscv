FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1

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

# WORKDIR /opt/gowin
# RUN wget https://cdn.gowinsemi.com.cn/Gowin_V1.9.11.03_Education_Linux.tar.gz
# RUN tar -xzf Gowin_V1.9.11.03_Education_Linux.tar.gz
# RUN rm Gowin_V1.9.11.03_Education_Linux.tar.gz

# RUN apt install -y --no-install-recommends \
#     libxcomposite1 \
#     libgl1 \
#     libxdamage1 \
#     libxfixes3 \
#     libxrandr2 \
#     libxtst6 \
#     libfontconfig1 \
#     libxkbcommon0 \
#     libdbus-1-3


# ENV QT_QPA_PLATFORM=offscreen
# ENV LD_PRELOAD=/lib/x86_64-linux-gnu/libfreetype.so.6

WORKDIR /rv32-bios
