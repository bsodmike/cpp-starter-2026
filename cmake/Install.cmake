include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Sanitizer and coverage flags are stripped from the exported interface (see the
# $<BUILD_INTERFACE:> link in src/core/CMakeLists.txt), which is right: a
# consumer must not inherit them. The consequence is that objects compiled here
# still reference the sanitizer runtime, so a package installed from such a
# build fails to link for anyone else. Install from the `release` preset.
if(ACME_ENABLE_SANITIZERS OR ACME_ENABLE_TSAN OR ACME_ENABLE_COVERAGE)
  message(WARNING
    "Sanitizers or coverage are enabled, so anything installed from this build "
    "tree is NOT redistributable: its objects reference the sanitizer/coverage "
    "runtime that consumers do not link. Use the 'release' preset to produce an "
    "installable package.")
endif()

# acme_options is exported because acme_core links it PUBLIC; acme_build_options
# is deliberately absent, since every target consumes it through
# $<BUILD_INTERFACE:> and its flags must not reach installed consumers.
install(TARGETS acme_core acme_options acme_app
  EXPORT ACMETargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  FILE_SET acme_core_headers DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

set(ACME_CMAKE_CONFIG_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ACME)

install(EXPORT ACMETargets
  FILE ACMETargets.cmake
  NAMESPACE acme::
  DESTINATION ${ACME_CMAKE_CONFIG_DESTINATION})

configure_package_config_file(
  ${CMAKE_CURRENT_LIST_DIR}/ACMEConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/ACMEConfig.cmake
  INSTALL_DESTINATION ${ACME_CMAKE_CONFIG_DESTINATION})

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/ACMEConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/ACMEConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/ACMEConfigVersion.cmake
  DESTINATION ${ACME_CMAKE_CONFIG_DESTINATION})

install(FILES
  ${PROJECT_SOURCE_DIR}/LICENSE
  ${PROJECT_SOURCE_DIR}/README.md
  DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/doc/ACME)
