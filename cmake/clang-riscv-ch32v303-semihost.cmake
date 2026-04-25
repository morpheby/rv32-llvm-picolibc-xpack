# RISC-V Clang Toolchain for CH32V303 — semihosting variant
#
# Targets the rv32imafc_ilp32f multilib variant (hardware FPU, no C++
# exceptions, no RTTI) and routes all I/O through the RISC-V semihosting
# ABI.  printf/scanf output goes to the connected debugger or QEMU session
# instead of a hardware UART; no ch32_hal or UART driver is needed.
#
# The application CMakeLists.txt must add a linker script that defines the
# target memory regions and includes picolibc.ld, e.g.:
#
#   target_link_options(<target> PRIVATE
#       -T${CMAKE_CURRENT_SOURCE_DIR}/ch32v303.ld)
#
# See tests/semihost_ch32v303/ for a complete example.
#
# See clang-riscv-ch32v.cmake for the standard firmware variant.
# See clang-riscv-common.cmake for all user-facing cache variables.

set(_CH32_DEFAULT_MARCH "rv32imafc_zicsr_zifencei_xwchc")
set(_CH32_DEFAULT_MABI  "ilp32f")
set(_CH32_NO_EXCEPTIONS TRUE)
set(_CH32_NO_RTTI       TRUE)

# Replace the ch32_hal / crt0 firmware combo with picolibc's semihost
# startup and I/O library.
set(_CH32_LINKER_LIBS "-lcrt0-semihost -lsemihost")

include("${CMAKE_CURRENT_LIST_DIR}/clang-riscv-common.cmake")
