#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) morpheby
#
# Portions derived from LLVM Embedded Toolchain for Arm
# (https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm)
# Copyright (c) 2020-2023, Arm Limited and affiliates.
#
# Build libc++, libc++abi and libunwind for RISC-V bare-metal variants
# (only variants that support full exceptions+RTTI or bare no-exn/no-RTTI).
#
# Expected environment variables:
#   WORKSPACE         - root working directory (default: $HOME/workspace)
#   DIST_DIR          - sysroot assembly directory (default: $WORKSPACE/rv32-llvm-picolibc)
#   INSTALL_PREFIX    - cmake install prefix (default: /usr/local/llvm-riscv)
#
# DIST_DIR/dist is used as the sysroot so that compiler-rt and picolibc
# are already present before building libcxx.  multilib.yaml must also be
# present at DIST_DIR/dist/multilib.yaml before this script runs.
#
# Run this script from within the llvm-project checkout directory.

set -e -o pipefail

WORKSPACE="${WORKSPACE:-$HOME/workspace}"
DIST_DIR="${DIST_DIR:-$WORKSPACE/rv32-llvm-picolibc}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/llvm-riscv}"

SYSROOT="${DIST_DIR}/dist"

# multilib.yaml must be present before the build so that clang can use
# multilib selection to locate the picolibc/compiler-rt headers and libs
# installed in the per-variant subdirectories of the sysroot.
mkdir -p "${SYSROOT}"
cp -f multilib.yaml "${SYSROOT}/"

variants=(
  rv32imafc-zicsr-zifencei-xwchc_ilp32f_exn_rtti
  rv32imafc-zicsr-zifencei-xwchc_ilp32f
  rv32imafc-zicsr-zifencei-xwchc_ilp32f_minimal
  rv32imac-zicsr-zifencei-xwchc_ilp32_exn_rtti
  rv32imac-zicsr-zifencei-xwchc_ilp32
  rv32imac-zicsr-zifencei-xwchc_ilp32_minimal
)

cmake_flags=(
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=YES -DLIBCXX_ENABLE_EXCEPTIONS=YES -DLIBCXXABI_ENABLE_STATIC_UNWINDER=YES -DLIBCXX_ENABLE_RTTI=YES -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_RTTI=ON"
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=NO -DLIBCXX_ENABLE_EXCEPTIONS=NO -DLIBCXXABI_ENABLE_STATIC_UNWINDER=NO -DLIBCXXABI_ENABLE_RTTI=NO -DLIBCXX_ENABLE_RTTI=NO -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=OFF"
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=NO -DLIBCXX_ENABLE_EXCEPTIONS=NO -DLIBCXXABI_ENABLE_STATIC_UNWINDER=NO -DLIBCXXABI_ENABLE_RTTI=NO -DLIBCXX_ENABLE_RTTI=NO -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DLIBCXX_ENABLE_LOCALIZATION=OFF -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF"
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=YES -DLIBCXX_ENABLE_EXCEPTIONS=YES -DLIBCXXABI_ENABLE_STATIC_UNWINDER=YES -DLIBCXX_ENABLE_RTTI=YES -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_RTTI=ON"
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=NO -DLIBCXX_ENABLE_EXCEPTIONS=NO -DLIBCXXABI_ENABLE_STATIC_UNWINDER=NO -DLIBCXXABI_ENABLE_RTTI=NO -DLIBCXX_ENABLE_RTTI=NO -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=OFF"
  "-DLIBCXXABI_ENABLE_EXCEPTIONS=NO -DLIBCXX_ENABLE_EXCEPTIONS=NO -DLIBCXXABI_ENABLE_STATIC_UNWINDER=NO -DLIBCXXABI_ENABLE_RTTI=NO -DLIBCXX_ENABLE_RTTI=NO -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXXABI_USE_LLVM_UNWINDER=OFF -DLIBCXX_ENABLE_LOCALIZATION=OFF -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF"
)

# Compile flags per variant.  The _minimal variants use the same architecture
# and exception/RTTI flags as their base counterparts; their distinction is
# in cmake_flags (LIBCXX_ENABLE_LOCALIZATION=OFF / LIBCXX_ENABLE_WIDE_CHARACTERS=OFF)
# and in how picolibc was built (-Dmb-capable=false).
flags=(
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto --sysroot=${SYSROOT}"
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto --sysroot=${SYSROOT} -fno-exceptions -fno-rtti"
  "-march=rv32imafc_zicsr_zifencei_xwchc -mabi=ilp32f -flto=auto --sysroot=${SYSROOT} -fno-exceptions -fno-rtti"  # minimal
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto --sysroot=${SYSROOT}"
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto --sysroot=${SYSROOT} -fno-exceptions -fno-rtti"
  "-march=rv32imac_zicsr_zifencei_xwchc -mabi=ilp32 -flto=auto --sysroot=${SYSROOT} -fno-exceptions -fno-rtti"  # minimal
)

# Which runtimes to build per variant.  Variants with exceptions need libunwind;
# no-exn and minimal variants only need libcxxabi and libcxx.
runtimes=(
  "libcxxabi;libcxx;libunwind"
  "libcxxabi;libcxx"
  "libcxxabi;libcxx"  # minimal
  "libcxxabi;libcxx;libunwind"
  "libcxxabi;libcxx"
  "libcxxabi;libcxx"  # minimal
)

for i in "${!variants[@]}" ; do
  b="${variants[$i]}"
  a="${flags[$i]}"

  COMMON_FLAGS="$a -D_GNU_SOURCE"
  CMAKE_FLAGS="${cmake_flags[$i]}"
  RUNTIMES="${runtimes[$i]}"

  # shellcheck disable=SC2086
  cmake -G Ninja -S runtimes -B "build-libcxx-${b}"                           \
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
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"                                \
    -DLLVM_ENABLE_RUNTIMES="${RUNTIMES}"                                      \
    -DLIBCXXABI_BAREMETAL=ON                                                  \
    -DLIBCXXABI_ENABLE_ASSERTIONS=OFF                                         \
    -DLIBCXXABI_ENABLE_SHARED=OFF                                             \
    -DLIBCXXABI_ENABLE_STATIC=ON                                              \
    -DLIBCXXABI_USE_COMPILER_RT=ON                                            \
    -DLIBCXX_ABI_UNSTABLE=ON                                                  \
    -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON                         \
    -DLIBCXX_ENABLE_FILESYSTEM=OFF                                            \
    -DLIBCXX_ENABLE_SHARED=OFF                                                \
    -DLIBCXX_ENABLE_STATIC=ON                                                 \
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF                                           \
    -DLIBCXX_INCLUDE_TESTS=OFF                                                \
    -DLIBUNWIND_ENABLE_ASSERTIONS=OFF                                         \
    -DLIBUNWIND_ENABLE_SHARED=OFF                                             \
    -DLIBUNWIND_ENABLE_STATIC=ON                                              \
    -DLIBUNWIND_IS_BAREMETAL=ON                                               \
    -DLIBUNWIND_REMEMBER_HEAP_ALLOC=ON                                        \
    -DLIBUNWIND_USE_COMPILER_RT=ON                                            \
    -DLIBUNWIND_TARGET_TRIPLE=riscv32-unknown-none-elf                        \
    -DRUNTIME_VARIANT_NAME="${b}"                                             \
    -DLIBCXXABI_ENABLE_THREADS=OFF                                            \
    -DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF                                       \
    -DLIBCXX_ENABLE_RANDOM_DEVICE=OFF                                         \
    -DLIBCXX_ENABLE_THREADS=OFF                                               \
    -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF                                       \
    -DLIBCXX_INSTALL_INCLUDE_TARGET_DIR=include-target                        \
    -DLIBUNWIND_ENABLE_THREADS=OFF                                            \
    -DRUNTIMES_USE_LIBC=picolibc                                              \
    -DLLVM_DEFAULT_TARGET_TRIPLE=riscv32-unknown-none-elf                     \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF                                  \
    -DLLVM_ENABLE_LTO=ON                                                      \
    -DCMAKE_ASM_COMPILER_TARGET=riscv32-unknown-none-elf                      \
    -DCMAKE_CXX_COMPILER_TARGET=riscv32-unknown-none-elf                      \
    -DCMAKE_C_COMPILER_TARGET=riscv32-unknown-none-elf                        \
    -DCMAKE_ASM_FLAGS="${COMMON_FLAGS}"                                       \
    -DCMAKE_C_FLAGS="${COMMON_FLAGS}"                                         \
    -DCMAKE_CXX_FLAGS="${COMMON_FLAGS}"                                       \
    ${CMAKE_FLAGS}                                                            \
    --fresh

  ninja -C "build-libcxx-${b}"
  DESTDIR="./dist" ninja -C "build-libcxx-${b}" install
  
  mkdir -p "${DIST_DIR}/dist/${b}/include"
  mkdir -p "${DIST_DIR}/dist/${b}/lib"
  mkdir -p "${DIST_DIR}/dist/${b}/share"
  mkdir -p "${DIST_DIR}/dist/include/"
  cp -R "build-libcxx-${b}/dist${INSTALL_PREFIX}/include-target/." "${DIST_DIR}/dist/${b}/include/"
  cp -R "build-libcxx-${b}/dist${INSTALL_PREFIX}/lib/." "${DIST_DIR}/dist/${b}/lib/"
  cp -R "build-libcxx-${b}/dist${INSTALL_PREFIX}/share/." "${DIST_DIR}/dist/${b}/share/"
  cp -R "build-libcxx-${b}/dist${INSTALL_PREFIX}/include/." "${DIST_DIR}/dist/include/"
done
