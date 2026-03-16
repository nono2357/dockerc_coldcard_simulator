# ─────────────────────────────────────────────────────────────────────────────
# ColdCard Firmware Simulator — Docker Image
# Based on: https://github.com/Coldcard/firmware (Linux setup instructions)
# Base: Ubuntu 22.04 (no micropython patch required, unlike Ubuntu 24.04)
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# ── 1. System dependencies ────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    autogen \
    build-essential \
    gcc-arm-none-eabi \
    git \
    libffi-dev \
    libltdl-dev \
    libpcsclite-dev \
    libsdl2-dev \
    libtool \
    libudev-dev \
    pkg-config \
    python-is-python3 \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    swig \
    xterm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ── 2. Clone firmware repo (recursive to pull all submodules) ─────────────────
WORKDIR /opt/coldcard
RUN git clone --recursive https://github.com/Coldcard/firmware.git .

# ── 3. Pre-fix the bundled libffi autotools files ─────────────────────────────
# The libffi submodule bundled inside micropython has stale autotools files
# that are incompatible with Ubuntu 22.04's autotools versions. Running
# autoreconf -fiv regenerates them in-place before make setup triggers them,
# resolving the "possibly undefined macro: LT_SYS_SYMBOL_USCORE" error.
RUN cd external/micropython/lib/libffi \
 && autoreconf -fiv

# ── 4. Python virtual environment ─────────────────────────────────────────────
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN pip install --no-cache-dir --upgrade pip setuptools \
 && pip install --no-cache-dir -r requirements.txt \
 && pip install --no-cache-dir pysdl2-dll

# ── 5. Build mpy-cross (MicroPython cross-compiler) ───────────────────────────
RUN make -C external/micropython/mpy-cross

# ── 6. Build the UNIX/desktop simulator ───────────────────────────────────────
RUN cd unix \
 && make setup \
 && make ngu-setup \
 && make \
 && make clean \
 && make setup COLDCARD=Q1 \
 && make COLDCARD=Q1

# ── Runtime ───────────────────────────────────────────────────────────────────
WORKDIR /opt/coldcard/unix

ENV COLDCARD_MODEL=mk4

VOLUME ["/opt/coldcard/unix/work"]

ENTRYPOINT ["/bin/sh", "-c", \
  "if [ \"$COLDCARD_MODEL\" = 'q1' ]; then python simulator.py --q1; else python simulator.py; fi"]
