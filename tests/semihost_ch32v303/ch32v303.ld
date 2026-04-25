/* Linker script for CH32V303 (rv32imafc) semihost builds.
 *
 * picolibc.ld defines the MEMORY block internally, reading the symbols
 * below via DEFINED() expressions.  Plain assignments (not PROVIDE) are
 * required so that the values are visible to MEMORY block expressions in
 * LLD.  __stack_size is required by picolibc.ld's heap-size calculation.
 *
 * Memory map (CH32V303xC):
 *   Flash: 256 KB at 0x08000000
 *   SRAM:   64 KB at 0x20000000
 */

__flash      = 0x08000000;
__flash_size = 256K;
__ram        = 0x20000000;
__ram_size   = 64K;
__stack_size = 1K;

INCLUDE picolibc.ld
