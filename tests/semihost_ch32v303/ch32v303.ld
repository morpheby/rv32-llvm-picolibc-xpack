/* Linker script for CH32V303 (rv32imafc) semihost builds.
 *
 * picolibc.ld already defines the MEMORY block internally, using the
 * symbols below as defaults.  We set those symbols here and then include
 * picolibc.ld so that it constructs the regions and places all sections.
 * Do NOT add a MEMORY block here — that would conflict with picolibc.ld.
 *
 * Memory map (CH32V303xC):
 *   Flash: 256 KB at 0x08000000
 *   SRAM:   64 KB at 0x20000000
 */

PROVIDE(__flash = 0x08000000);
PROVIDE(__flash_size = 256K);
PROVIDE(__ram = 0x20000000);
PROVIDE(__ram_size = 64K);

INCLUDE picolibc.ld
