cmake_minimum_required(VERSION 3.20)
project(SemihostCH32V303Test C)

add_definitions(
    -D_PICOLIBC_PRINTF='f'
    -D_PICOLIBC_SCANF='m'
)

add_executable(semihost_ch32v303 main.c)

target_link_libraries(semihost_ch32v303 PRIVATE
    crt0-semihost
    semihost
)

target_link_options(semihost_ch32v303 PRIVATE
    -Wl,--defsym=vfprintf=__f_vfprintf
    -Wl,--defsym=vfscanf=__m_vfscanf
    -T${CMAKE_CURRENT_SOURCE_DIR}/ch32v303.ld)
