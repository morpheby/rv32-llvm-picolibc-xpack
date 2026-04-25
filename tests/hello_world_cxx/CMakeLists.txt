cmake_minimum_required(VERSION 3.20)
project(HelloWorldCxxTest C CXX)

add_definitions(
    -D_PICOLIBC_PRINTF='f'
    -D_PICOLIBC_SCANF='m'
)

add_executable(hello_world_cxx main.cpp os.c)

target_link_libraries(hello_world_cxx PRIVATE
    c++
    crt0
)

target_link_options(hello_world_cxx PRIVATE
    -Wl,--defsym=vfprintf=__f_vfprintf
    -Wl,--defsym=vfscanf=__m_vfscanf
    -T${CMAKE_CURRENT_SOURCE_DIR}/ch32v303.ld)
