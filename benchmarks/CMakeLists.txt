find_package(benchmark CONFIG REQUIRED)

add_executable(acme_core_benchmark text_benchmark.cpp)

target_link_libraries(acme_core_benchmark
  PRIVATE
    acme::core
    acme::options
    $<BUILD_INTERFACE:acme::build_options>
    benchmark::benchmark
    benchmark::benchmark_main)
