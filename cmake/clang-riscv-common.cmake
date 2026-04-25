# RISC-V Clang Toolchain — shared logic
#
# This file is meant to be included by a variant-specific wrapper, not used
# directly as a CMAKE_TOOLCHAIN_FILE.  The wrapper must set the following
# internal variables before including this file:
#
#   _CH32_DEFAULT_MARCH   Default -march string for the target family
#                         (e.g. "rv32imafc_zicsr_zifencei_xwchc")
#   _CH32_DEFAULT_MABI    Default -mabi string (e.g. "ilp32f")
#   _CH32_NO_EXCEPTIONS   TRUE: add -fno-exceptions to compile flags
#   _CH32_NO_RTTI         TRUE: add -fno-rtti to compile flags
#
# The resulting configuration selects the corresponding multilib variant
# automatically via the multilib.yaml embedded in the sysroot.
#
# Settings:
#   TOOLCHAIN_PATH - path to clang bin/ directory (empty = use PATH)
#   CH32_MARCH     - RISC-V -march string (defaults to _CH32_DEFAULT_MARCH)
#   CH32_MABI      - RISC-V -mabi string  (defaults to _CH32_DEFAULT_MABI)
#
# Note: Some LLVM builds distributed not from llvm.org don't support all architecture flags/variants
# needed to build CH32V firmware. Ideally you should always rely on llvm.org-provided releases.
#
# Note (macOS): LLVM packaged with Xcode DOES NOT support RISC-V. Download a release from llvm.org.

cmake_minimum_required(VERSION 3.20)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ----- Toolchain prefix -----
set(CROSS_COMPILE "riscv-unknown-none-elf-" CACHE STRING "Toolchain prefix")

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

get_filename_component(LLVM_TOOLCHAIN
    "${CMAKE_CURRENT_LIST_DIR}/../dist" ABSOLUTE)

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
