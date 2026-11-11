cmake_minimum_required(VERSION 3.30...4.4)

project(ACME
  VERSION 0.1.0
  DESCRIPTION "C++23 project skeleton: CMake presets, vcpkg, sanitizers, three-OS CI"
  HOMEPAGE_URL "https://github.com/inertialbox/experiment-cpp-starter"
  LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(CompilerFloor)
include(ProjectWarnings)
include(Sanitizers)
include(Hardening)
include(Coverage)
include(BuildAccel)

# Developer-friendly defaults only when ACME is the top-level project; a parent
# project that pulls us in via add_subdirectory() gets the quiet variants.
option(ACME_BUILD_TESTS "Build the test suite" ${PROJECT_IS_TOP_LEVEL})
option(ACME_BUILD_BENCHMARKS "Build benchmarks" OFF)
option(ACME_ENABLE_SANITIZERS "Enable ASan + UBSan" OFF)
option(ACME_ENABLE_TSAN "Enable ThreadSanitizer (mutually exclusive with ASan)" OFF)
option(ACME_ENABLE_HARDENING "Enable release hardening flags" OFF)
option(ACME_ENABLE_LIBRARY_HARDENING "Enable standard-library assertions" ${PROJECT_IS_TOP_LEVEL})
option(ACME_WARNINGS_AS_ERRORS "Promote warnings to errors (CI only)" OFF)
option(ACME_ENABLE_COVERAGE "Instrument for coverage reporting" OFF)
option(ACME_ENABLE_IPO "Enable link-time optimisation where supported" OFF)
option(ACME_ENABLE_CXX26 "Opt into C++26 features; never in public headers" OFF)
option(ACME_ALLOW_UNSUPPORTED_COMPILER "Bypass the compiler floor check" OFF)
option(ACME_USE_COMPILER_CACHE "Use ccache/sccache when present" ON)
option(ACME_USE_FAST_LINKER "Use mold/lld when present" ON)
option(ACME_SANITIZER_SELFTEST "Build the sanitizer self-test binaries" OFF)

acme_check_compiler_floor()

# No target uses named modules in v1 (see
# docs/adrs/2026-11-11.adr-headers-not-modules.md), but CMake scans every
# C++20-or-later source for module dependencies by default, which costs one
# clang-scan-deps (or /scanDependencies) run per translation unit for no
# benefit. Drop this line when the modules spike adopts them.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

if(PROJECT_IS_TOP_LEVEL)
  set(CMAKE_CXX_STANDARD 23)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)
endif()

acme_setup_build_accel()

# Public usage requirements: whatever a consumer of an installed ACME must also
# compile with. This target is exported, so keep it ABI-relevant only.
add_library(acme_options INTERFACE)
add_library(acme::options ALIAS acme_options)
target_compile_features(acme_options INTERFACE cxx_std_23)
acme_apply_library_hardening(acme_options)

# Build-only strictness. Linked through $<BUILD_INTERFACE:> so warnings,
# sanitizers and coverage apply to this build tree and never reach a consumer
# of the installed package.
add_library(acme_build_options INTERFACE)
add_library(acme::build_options ALIAS acme_build_options)
acme_apply_warnings(acme_build_options)
acme_apply_sanitizers(acme_build_options)
acme_apply_hardening(acme_build_options)
acme_apply_coverage(acme_build_options)

if(ACME_ENABLE_CXX26)
  # Opt-in per build, never assumed by public headers: see
  # docs/adrs/2026-11-11.adr-cxx23-baseline.md.
  target_compile_features(acme_build_options INTERFACE cxx_std_26)
  target_compile_definitions(acme_build_options INTERFACE ACME_HAS_CXX26=1)
endif()

# LTO is applied to executables only, never to the installed library: a static
# library built with -flto holds LLVM bitcode (or MSVC IR), which a consumer can
# only link with a matching, LTO-aware toolchain and which plain `ld` rejects
# outright with "file format not recognized". Executables have no such contract.
set(ACME_IPO_ENABLED OFF)
if(ACME_ENABLE_IPO)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT acme_ipo_ok OUTPUT acme_ipo_why)
  if(acme_ipo_ok)
    set(ACME_IPO_ENABLED ON)
  else()
    message(WARNING "LTO requested but unsupported: ${acme_ipo_why}")
  endif()
endif()

add_subdirectory(src/core)
add_subdirectory(app)

if(ACME_BUILD_TESTS)
  include(CTest)
  add_subdirectory(tests)
endif()

if(ACME_BUILD_BENCHMARKS)
  add_subdirectory(benchmarks)
endif()

if(PROJECT_IS_TOP_LEVEL)
  include(Install)
  include(Packaging)
endif()
