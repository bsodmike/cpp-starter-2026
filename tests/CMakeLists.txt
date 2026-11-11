find_package(GTest CONFIG REQUIRED)
include(GoogleTest)

# One test binary per library, per the PRD repository rules.
add_executable(acme_core_test
  text_test.cpp
  version_test.cpp)

target_link_libraries(acme_core_test
  PRIVATE
    acme::core
    acme::options
    $<BUILD_INTERFACE:acme::build_options>
    GTest::gtest
    GTest::gtest_main)

gtest_discover_tests(acme_core_test
  DISCOVERY_TIMEOUT 30
  PROPERTIES LABELS unit)

# Proof that the sanitizers are wired up: each binary contains one deliberate
# defect, and the test passes only when the sanitizer reports it. These are the
# executable form of two PRD acceptance criteria, so they live in the normal
# test suite instead of being a manual check.
if(ACME_SANITIZER_SELFTEST)
  if(NOT ACME_ENABLE_SANITIZERS)
    message(FATAL_ERROR "ACME_SANITIZER_SELFTEST=ON requires ACME_ENABLE_SANITIZERS=ON.")
  endif()

  set(acme_selftest_cases asan_out_of_bounds "ERROR: AddressSanitizer")
  if(NOT MSVC)
    # MSVC ships ASan only; it has no UBSan.
    list(APPEND acme_selftest_cases ubsan_signed_overflow "runtime error:.*signed integer overflow")
  endif()

  while(acme_selftest_cases)
    list(POP_FRONT acme_selftest_cases case pattern)

    add_executable(acme_selftest_${case} selftest/${case}.cpp)
    target_link_libraries(acme_selftest_${case}
      PRIVATE acme::options $<BUILD_INTERFACE:acme::build_options>)

    add_test(NAME sanitizer.${case}
      COMMAND ${CMAKE_COMMAND}
        -DTEST_COMMAND=$<TARGET_FILE:acme_selftest_${case}>
        -DEXPECT_PATTERN=${pattern}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/expect_sanitizer_failure.cmake)
    set_tests_properties(sanitizer.${case} PROPERTIES LABELS sanitizer-selftest)
  endwhile()
endif()
