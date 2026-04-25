cmake_minimum_required(VERSION 3.20)
project(SemihostCH32V303Test C)

add_compile_options(
    -D_PICOLIBC_PRINTF='f'
    -D_PICOLIBC_SCANF='m'
)

add_executable(semihost_ch32v303 main.c)

target_link_options(semihost_ch32v303 PRIVATE
    -lcrt0-semihost -lsemihost
    -Wl,--defsym=vfprintf=__f_vfprintf
    -Wl,--defsym=vfscanf=__m_vfscanf
    -T${CMAKE_CURRENT_SOURCE_DIR}/ch32v303.ld)
