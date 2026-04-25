#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) morpheby
#
# Portions derived from LLVM Embedded Toolchain for Arm
# (https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm)
# Copyright (c) 2020-2023, Arm Limited and affiliates.
#
# Build picolibc for all RISC-V bare-metal variants.
#
# Expected environment variables:
#   WORKSPACE                 - root working directory (default: $HOME/workspace)
#   DIST_DIR                  - sysroot assembly directory (default: $WORKSPACE/rv32-llvm-picolibc)
#   PICOLIBC_PREFIX           - meson install prefix (default: /usr/local)
#   PICOLIBC_CROSS_FILES_DIR  - directory containing meson cross-files
#                               (default: $WORKSPACE/rv32-llvm-picolibc-xpack/picolibc-cross-files)
#
# Run this script from within the picolibc checkout directory.

set -e -o pipefail

WORKSPACE="${WORKSPACE:-$HOME/workspace}"
DIST_DIR="${DIST_DIR:-$WORKSPACE/rv32-llvm-picolibc}"
PICOLIBC_PREFIX="${PICOLIBC_PREFIX:-/usr/local}"
PICOLIBC_CROSS_FILES_DIR="${PICOLIBC_CROSS_FILES_DIR:-$WORKSPACE/rv32-llvm-picolibc-xpack/picolibc-cross-files}"

mkdir -p "${DIST_DIR}/dist"

for s in "${PICOLIBC_CROSS_FILES_DIR}"/*.txt ; do
  b="$(basename "$s")"
  b="${b%.*}"

  if [[ "${b}" == *_minimal ]]; then
    MB_CAPABLE=false
  else
    MB_CAPABLE=true
  fi

  meson setup "build-${b}/"       \
    --cross-file="${s}"           \
    --prefix="${PICOLIBC_PREFIX}" \
    -Dspecsdir=none               \
    -Dincludedir=include          \
    -Dlibdir=lib                  \
    -Dmb-capable=${MB_CAPABLE}    \
    -Dmultilib=false              \
    --buildtype=minsize           \
    --reconfigure

  ninja -C "build-${b}"
  DESTDIR="./dist" ninja -C "build-${b}" install

  mkdir -p "${DIST_DIR}/dist/${b}/"
  cp -R "build-${b}/dist${PICOLIBC_PREFIX}/." "${DIST_DIR}/dist/${b}/"
done
