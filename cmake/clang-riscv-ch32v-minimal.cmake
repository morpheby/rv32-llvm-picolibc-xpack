# RISC-V Clang Toolchain for CH32V series MCUs — no exceptions, no RTTI, no locale
#
# Targets the rv32imafc_ilp32f_minimal multilib variant (hardware FPU, no C++
# exceptions, no RTTI, no localization or wide-character support).  Suited for
# size-critical firmware where locale and mb/wchar overhead must be eliminated.
#
# Users must add -D_PICOLIBC_NO_LOCALE=1 to their compile flags (set here via
# _CH32_EXTRA_FLAGS) so that clang's multilib selection picks this variant.
#
# See clang-riscv-ch32v.cmake for the leaner no-exceptions / no-RTTI variant.
# See clang-riscv-ch32v-exn-rtti.cmake for the variant with full C++ support.
# See clang-riscv-common.cmake for all user-facing cache variables.

set(_CH32_DEFAULT_MARCH "rv32imafc_zicsr_zifencei_xwchc")
set(_CH32_DEFAULT_MABI  "ilp32f")
set(_CH32_NO_EXCEPTIONS TRUE)
set(_CH32_NO_RTTI       TRUE)
set(_CH32_EXTRA_FLAGS   "-D_PICOLIBC_NO_LOCALE=1")

include("${CMAKE_CURRENT_LIST_DIR}/clang-riscv-common.cmake")
