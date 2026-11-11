# Source and binary archives for release artifacts; the release workflow runs
# `cpack --preset release` and publishes the result with checksums and an SBOM.
set(CPACK_PACKAGE_NAME "acme")
set(CPACK_PACKAGE_VENDOR "ACME")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
set(CPACK_PACKAGE_HOMEPAGE_URL "${PROJECT_HOMEPAGE_URL}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE")
set(CPACK_PACKAGE_FILE_NAME
  "acme-${PROJECT_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}")
set(CPACK_VERBATIM_VARIABLES ON)
set(CPACK_STRIP_FILES ON)

if(WIN32)
  set(CPACK_GENERATOR ZIP)
else()
  set(CPACK_GENERATOR TGZ)
endif()

set(CPACK_SOURCE_GENERATOR TGZ)
set(CPACK_SOURCE_IGNORE_FILES
  "/\\\\.git/"
  "/build.*/"
  "/\\\\.cache/"
  "/vcpkg_installed/"
  "CMakeUserPresets\\\\.json")

include(CPack)
