cmake_minimum_required(VERSION 3.20)
project(SemihostCxxTest CXX)

add_definitions(
    -D_PICOLIBC_PRINTF='f'
    -D_PICOLIBC_SCANF='m'
)

add_executable(semihost_cxx main.cpp)

target_link_libraries(semihost_cxx PRIVATE
    c++
    crt0-semihost
    semihost
)

target_link_options(semihost_cxx PRIVATE
    -Wl,--defsym=vfprintf=__f_vfprintf
    -Wl,--defsym=vfscanf=__m_vfscanf
    -T${CMAKE_CURRENT_SOURCE_DIR}/ch32v303.ld)
