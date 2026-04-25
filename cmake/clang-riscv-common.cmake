# RISC-V Clang Toolchain — shared logic
#
# This file is meant to be included by a variant-specific wrapper, not used
# directly as a CMAKE_TOOLCHAIN_FILE.  The wrapper must set the following
# internal variables before including this file:
#
#   _CH32_DEFAULT_MARCH   Default -march string for the target family
#                         (e.g. "rv32imafc_zicsr_zifencei_xwchc")
#   _CH32_DEFAULT_MABI    Default -mabi string (e.g. "ilp32f")
#   _CH32_NO_EXCEPTIONS   TRUE → add -fno-exceptions to compile flags
#   _CH32_NO_RTTI         TRUE → add -fno-rtti to compile flags
#
# The resulting configuration selects the corresponding multilib variant
# automatically via the multilib.yaml embedded in the sysroot.
#
# User-facing cache variables (can be overridden on the cmake command line):
#   LLVM_TOOLCHAIN - sysroot root directory (contains dist/ with multilib.yaml);
#                    auto-inferred as <cmake-dir>/../dist when using a release
#                    tarball — no need to set this manually in that case
#   TOOLCHAIN_PATH - path to clang bin/ directory (empty = use PATH)
#   CH32_MARCH     - RISC-V -march string (defaults to _CH32_DEFAULT_MARCH)
#   CH32_MABI      - RISC-V -mabi string  (defaults to _CH32_DEFAULT_MABI)

cmake_minimum_required(VERSION 3.20)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----- Toolchain prefix -----
set(CROSS_COMPILE "riscv-unknown-none-elf-" CACHE STRING "Toolchain prefix")

# ----- Local developer config (LLVM_TOOLCHAIN etc.) -----
include("${CMAKE_CURRENT_LIST_DIR}/../local-config.cmake" OPTIONAL)

# ----- Toolchain path detection -----
if(NOT DEFINED TOOLCHAIN_PATH)
    # Assume clang is on PATH (set up by activate.sh / activate.ps1)
    set(TOOLCHAIN_PATH "" CACHE PATH "Toolchain bin/ directory (empty = use PATH)")
endif()

if(TOOLCHAIN_PATH)
    set(_PREFIX "${TOOLCHAIN_PATH}/")
else()
    set(_PREFIX "")
endif()

# On Windows, full-path compiler references need the .exe suffix.
if(CMAKE_HOST_WIN32 AND TOOLCHAIN_PATH)
    set(_EXE ".exe")
else()
    set(_EXE "")
endif()

# ----- Compilers -----
set(CMAKE_C_COMPILER   "${_PREFIX}clang${_EXE}"        CACHE FILEPATH "" FORCE)
set(CMAKE_CXX_COMPILER "${_PREFIX}clang++${_EXE}"      CACHE FILEPATH "" FORCE)
set(CMAKE_ASM_COMPILER "${_PREFIX}clang${_EXE}"        CACHE FILEPATH "" FORCE)
set(CMAKE_OBJCOPY      "${_PREFIX}llvm-objcopy${_EXE}" CACHE FILEPATH "" FORCE)
set(CMAKE_OBJDUMP      "${_PREFIX}llvm-objdump${_EXE}" CACHE FILEPATH "" FORCE)
set(CMAKE_SIZE_UTIL    "${_PREFIX}llvm-size${_EXE}"    CACHE FILEPATH "" FORCE)
set(CMAKE_AR           "${_PREFIX}llvm-ar${_EXE}"      CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB       "${_PREFIX}llvm-ranlib${_EXE}"  CACHE FILEPATH "" FORCE)

# ----- Architecture flags -----
set(CH32_MARCH "${_CH32_DEFAULT_MARCH}" CACHE STRING "RISC-V -march value")
set(CH32_MABI  "${_CH32_DEFAULT_MABI}"  CACHE STRING "RISC-V -mabi value")

set(ARCH_FLAGS
    --target=riscv32-unknown-none-elf
    -march=${CH32_MARCH}
    -mabi=${CH32_MABI}
    -msmall-data-limit=8
    -msave-restore
)

string(JOIN " " ARCH_FLAGS_STR ${ARCH_FLAGS})

# ----- Sysroot (from LLVM_TOOLCHAIN root) -----
# LLVM_TOOLCHAIN may be provided by (in decreasing priority):
#   1. -DLLVM_TOOLCHAIN=<path> on the cmake command line
#   2. local-config.cmake (included above)
#   3. Auto-inferred as <cmake-dir>/../dist when using a release tarball
#      (where cmake/ and dist/ are placed as siblings by package-dist.sh)
#
# The toolchain uses multilib; clang selects the correct variant automatically
# from the -march/-mabi/-fno-exceptions/-fno-rtti flags via multilib.yaml.
if(NOT LLVM_TOOLCHAIN)
    get_filename_component(_INFERRED_SYSROOT
        "${CMAKE_CURRENT_LIST_DIR}/../dist" ABSOLUTE)
    if(EXISTS "${_INFERRED_SYSROOT}")
        set(LLVM_TOOLCHAIN "${_INFERRED_SYSROOT}"
            CACHE PATH "Sysroot directory (auto-inferred from toolchain file location)")
        message(STATUS "LLVM_TOOLCHAIN auto-inferred: ${LLVM_TOOLCHAIN}")
    endif()
endif()

if(NOT LLVM_TOOLCHAIN)
    message(FATAL_ERROR
        "LLVM_TOOLCHAIN is not set and could not be auto-inferred.\n"
        "Expected a dist/ directory next to the cmake/ directory "
        "(standard release tarball layout).\n"
        "Set it explicitly with -DLLVM_TOOLCHAIN=<path> or via local-config.cmake.")
endif()
if(NOT EXISTS "${LLVM_TOOLCHAIN}")
    message(FATAL_ERROR
        "LLVM_TOOLCHAIN directory not found: ${LLVM_TOOLCHAIN}\n"
        "Check the path set via -DLLVM_TOOLCHAIN or in local-config.cmake.")
endif()

# ----- Exception / RTTI flags -----
set(_EXN_RTTI_FLAGS "")
if(_CH32_NO_EXCEPTIONS)
    list(APPEND _EXN_RTTI_FLAGS -fno-exceptions)
endif()
if(_CH32_NO_RTTI)
    list(APPEND _EXN_RTTI_FLAGS -fno-rtti)
endif()

# ----- Common compile flags -----
set(COMMON_FLAGS
    --sysroot=${LLVM_TOOLCHAIN}
    ${ARCH_FLAGS}
    -Os -ffast-math
    -Wall
    -fmessage-length=0
    -fsigned-char
    -ffunction-sections
    -fdata-sections
    -fno-common
    -flto=full
    -fvirtual-function-elimination
    -fwhole-program-vtables
    ${_EXN_RTTI_FLAGS}
    ${_CH32_EXTRA_FLAGS}
    -fcolor-diagnostics
    -D_PICOLIBC_PRINTF='f'
    -D_PICOLIBC_SCANF='m'
    -D_GNU_SOURCE=1
    -fconstexpr-steps=134217728
)

string(JOIN " " COMMON_FLAGS_STR ${COMMON_FLAGS})

set(CMAKE_C_FLAGS_INIT   "-std=gnu23 ${COMMON_FLAGS_STR}")
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS_STR} -std=gnu++20 -fno-threadsafe-statics -fno-use-cxa-atexit -fpermissive")
set(CMAKE_ASM_FLAGS_INIT "${ARCH_FLAGS_STR} --target=riscv32-unknown-none-elf -x assembler-with-cpp")

# ----- Linker flags -----
# NOTE: -lch32_hal must be provided by the application project (via
#       third_party/ch32_hal or an equivalent target).  Adjust the -L path to
#       match the project layout.
# NOTE: For the exn+rtti variants (i.e. when _CH32_NO_EXCEPTIONS is FALSE),
#       add -lc++ to the project's link step to pull in libc++, libc++abi and
#       libunwind (all statically linked inside libc++.a in the sysroot).
set(CMAKE_EXE_LINKER_FLAGS_INIT
    "--sysroot=${LLVM_TOOLCHAIN} ${ARCH_FLAGS_STR} \
-Wl,--gc-sections \
-lch32_hal -lcrt0 -lcrt0-inittls \
-Wl,--defsym=vfprintf=__f_vfprintf \
-Wl,--defsym=vfscanf=__m_vfscanf \
-nostartfiles \
-Lthird_party/ch32_hal")

# TODO: Those are some things Espressif uses for optimization. Consider the impact later.
    # -mllvm -inline-threshold=500
    # -mllvm -unroll-threshold=450
    # -mllvm -unroll-partial-threshold=450
    # -mllvm -unroll-max-iteration-count-to-analyze=20
    # -mllvm -lsr-complexity-limit=1073741823
    # -mllvm -force-attribute=main:norecurse

set(CMAKE_C_USING_LINKER_LLD "-fuse-ld=lld")
set(CMAKE_CXX_USING_LINKER_LLD "-fuse-ld=lld")
set(CMAKE_LINKER_TYPE LLD)

# ----- Debug / Release flag overrides -----
# The project always uses -Os; debug adds symbols only.
set(CMAKE_C_FLAGS_DEBUG            "-ggdb2" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_DEBUG          "-ggdb2" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE          ""       CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE        ""       CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_MINSIZEREL       ""       CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_MINSIZEREL     ""       CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO   "-ggdb2" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-ggdb2" CACHE STRING "" FORCE)

# ----- Search paths -----
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
