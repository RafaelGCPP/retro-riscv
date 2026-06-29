FROM debian:trixie AS base

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

FROM base AS yosysbuild

RUN apt-get install -y \
    gawk \
    git \
    make \
    python3 \
    lld \
    bison \
    clang \
    flex \
	libffi-dev \
    libfl-dev \
    libreadline-dev \
    pkg-config \
    tcl-dev \
    zlib1g-dev \
	graphviz \
    xdot

WORKDIR /src
RUN git clone --recurse-submodules https://github.com/YosysHQ/yosys.git

WORKDIR /src/yosys
RUN cmake -B build . -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build --config Release --parallel $(nproc)
RUN cmake --install build --strip


FROM base AS nextpnrbuild

RUN apt-get install -y  --no-install-recommends \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-thread-dev \
    libboost-program-options-dev \
    libboost-iostreams-dev \
    libboost-dev \
    python3-dev \
    python3-pybind11 \
    libeigen3-dev

RUN pip install apycula

WORKDIR /src
RUN git clone --recurse-submodules https://github.com/YosysHQ/nextpnr.git

WORKDIR /src/nextpnr
RUN cmake -B build . -DARCH="himbaechel" -DHIMBAECHEL_UARCH="gowin" -DCMAKE_BUILD_TYPE=Release

WORKDIR /src/nextpnr/build
RUN make -j$(nproc)
RUN make install


FROM base AS openfpgaloaderbuild

RUN apt install -y --no-install-recommends \
  git \
  gzip \
  libftdi1-2 \
  libftdi1-dev \
  libhidapi-hidraw0 \
  libhidapi-dev \
  libudev-dev \
  zlib1g-dev \
  cmake \
  pkg-config \
  make \
  g++

WORKDIR /src
RUN git clone --recurse-submodules https://github.com/trabucayre/openFPGALoader.git

WORKDIR /src/openFPGALoader
RUN cmake -B build . -DCMAKE_BUILD_TYPE=Release

RUN cmake --build build --config Release --parallel $(nproc)
RUN cmake --install build --strip


FROM base AS runtime

RUN apt-get install -y \
    libtcl8.6 \
    libboost-program-options1.83.0 \
    libboost-iostreams1.83.0 \
    libboost-thread1.83.0 \
    libboost-filesystem1.83.0 \
    libpython3.13 \
    libusb-1.0-0 \
    libftdi1-2 \
    libhidapi-libusb0

RUN pip install apycula
COPY --from=yosysbuild /usr/local/ /usr/local/
COPY --from=nextpnrbuild /usr/local/ /usr/local/
COPY --from=openfpgaloaderbuild /usr/local/ /usr/local/

