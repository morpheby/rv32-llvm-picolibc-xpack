#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) morpheby
#
# Portions derived from LLVM Embedded Toolchain for Arm
# (https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm)
# Copyright (c) 2020-2023, Arm Limited and affiliates.
#
# Build compiler-rt builtins for all RISC-V bare-metal variants.
#
# Expected environment variables:
#   WORKSPACE         - root working directory (default: $HOME/workspace)
#   DIST_DIR          - sysroot assembly directory (default: $WORKSPACE/rv32-llvm-picolibc)
#   INSTALL_PREFIX    - cmake install prefix (default: /usr/local/llvm-riscv)
#
# Run this script from within the llvm-project checkout directory.

set -e -o pipefail

WORKSPACE="${WORKSPACE:-$HOME/workspace}"
DIST_DIR="${DIST_DIR:-$WORKSPACE/rv32-llvm-picolibc}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/llvm-riscv}"

mkdir -p "${DIST_DIR}/dist"

variants=(
  rv32imafc-zicsr-zifencei-xwchc_ilp32f_exn_rtti
  rv32imafc-zicsr-zifencei-xwchc_ilp32f
  rv32imafc-zicsr-zifencei-xwchc_ilp32f_minimal
  rv32imac-zicsr-zifencei-xwchc_ilp32_exn_rtti
  rv32imac-zicsr-zifencei-xwchc_ilp32
  rv32imac-zicsr-zifencei-xwchc_ilp32_minimal
)

flags=(
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto"
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto -fno-exceptions -fno-rtti"
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto -fno-exceptions -fno-rtti"
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto"
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto -fno-exceptions -fno-rtti"
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto -fno-exceptions -fno-rtti"
)

for i in "${!variants[@]}" ; do
  b="${variants[$i]}"
  a="${flags[$i]}"

  COMMON_FLAGS="$a"
  cmake -G Ninja -S runtimes -B "build-compiler_rt-${b}"                      \
    -DLLVM_INCLUDE_TESTS=OFF                                                  \
    -DCMAKE_AR="$(which llvm-ar)"                                             \
    -DCMAKE_CXX_COMPILER="$(which clang++)"                                   \
    -DCMAKE_C_COMPILER="$(which clang)"                                       \
    -DCMAKE_NM="$(which llvm-nm)"                                             \
    -DCMAKE_RANLIB="$(which llvm-ranlib)"                                     \
    -DLLVM_USE_LINKER=lld                                                     \
    -DCMAKE_SYSTEM_NAME=Generic                                               \
    -DCMAKE_BUILD_TYPE=Release                                                \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY                            \
    -DLLVM_HOST_TRIPLE=riscv32-unknown-none-elf                               \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"                                 \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt"                                      \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON                                          \
    -DCOMPILER_RT_BUILD_BUILTINS=ON                                           \
    -DCOMPILER_RT_BUILD_PROFILE=OFF                                           \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF                                         \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF                                        \
    -DCOMPILER_RT_BUILD_XRAY=OFF                                              \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON                                      \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON                                   \
    -DCMAKE_ASM_COMPILER_TARGET=riscv32-unknown-none-elf                      \
    -DCMAKE_CXX_COMPILER_TARGET=riscv32-unknown-none-elf                      \
    -DCMAKE_C_COMPILER_TARGET=riscv32-unknown-none-elf                        \
    -DCMAKE_ASM_FLAGS="${COMMON_FLAGS}"                                       \
    -DCMAKE_C_FLAGS="${COMMON_FLAGS}"                                         \
    -DCMAKE_CXX_FLAGS="${COMMON_FLAGS}"                                       \
    --fresh

  ninja -C "build-compiler_rt-${b}"
  DESTDIR="./dist" ninja -C "build-compiler_rt-${b}" install

  mkdir -p "${DIST_DIR}/dist/${b}/include"
  mkdir -p "${DIST_DIR}/dist/${b}/lib"
  cp -R "build-compiler_rt-${b}/dist${INSTALL_PREFIX}/include/"* \
    "${DIST_DIR}/dist/${b}/include/"
  cp -R "build-compiler_rt-${b}/dist${INSTALL_PREFIX}/lib/riscv32-unknown-none-elf/"* \
    "${DIST_DIR}/dist/${b}/lib/"
done
