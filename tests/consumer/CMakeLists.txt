# Standalone project: proves `cmake --install` plus `find_package(ACME)` works
# from outside the build tree. CI configures this against the install prefix,
# so it must never be add_subdirectory()'d by the main build.
cmake_minimum_required(VERSION 3.30...4.4)

project(acme_consumer LANGUAGES CXX)

find_package(ACME 0.1 CONFIG REQUIRED)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE acme::core)

enable_testing()
add_test(NAME consumer.runs COMMAND consumer)
