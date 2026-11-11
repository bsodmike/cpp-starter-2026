add_library(acme_core
  text.cpp
  version.cpp)
add_library(acme::core ALIAS acme_core)

target_include_directories(acme_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

target_compile_definitions(acme_core PRIVATE
  ACME_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
  ACME_VERSION_MINOR=${PROJECT_VERSION_MINOR}
  ACME_VERSION_PATCH=${PROJECT_VERSION_PATCH}
  ACME_VERSION_STRING="${PROJECT_VERSION}")

target_link_libraries(acme_core
  PUBLIC acme::options
  PRIVATE $<BUILD_INTERFACE:acme::build_options>)

set_target_properties(acme_core PROPERTIES
  EXPORT_NAME core
  VERSION ${PROJECT_VERSION}
  SOVERSION ${PROJECT_VERSION_MAJOR}
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  POSITION_INDEPENDENT_CODE ON)

target_sources(acme_core PUBLIC
  FILE_SET acme_core_headers
  TYPE HEADERS
  BASE_DIRS include
  FILES
    include/acme/core/text.hpp
    include/acme/core/version.hpp)
