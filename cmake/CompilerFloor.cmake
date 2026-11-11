# Compiler floors. CI pins exact versions via .tool-versions; this check only
# stops builds below the supported floor.
#
# AppleClang is versioned independently of Xcode, so an Xcode version is not a
# usable floor here: Xcode 26.x reports AppleClang 21.0.0, tracking the upstream
# LLVM release it is built from rather than the Xcode release it ships in. The
# floor below is therefore chosen from library support instead - AppleClang 17
# is the LLVM 17 era, by which libc++ has both <expected> and <format>, the two
# C++23 library features acme::core depends on.
set(ACME_FLOOR_GCC 14)
set(ACME_FLOOR_CLANG 21)
set(ACME_FLOOR_APPLECLANG 17.0)
set(ACME_FLOOR_MSVC 19.50)

function(acme_check_compiler_floor)
  set(id "${CMAKE_CXX_COMPILER_ID}")
  set(ver "${CMAKE_CXX_COMPILER_VERSION}")

  if(id STREQUAL "GNU")
    set(floor ${ACME_FLOOR_GCC})
  elseif(id STREQUAL "Clang")
    set(floor ${ACME_FLOOR_CLANG})
  elseif(id STREQUAL "AppleClang")
    set(floor ${ACME_FLOOR_APPLECLANG})
  elseif(id STREQUAL "MSVC")
    set(floor ${ACME_FLOOR_MSVC})
  else()
    message(WARNING "Untested compiler '${id}'; the project supports GCC, Clang, AppleClang and MSVC.")
    return()
  endif()

  if(ver VERSION_LESS floor)
    set(msg "${id} ${ver} is below the supported floor ${id} ${floor}.")
    if(ACME_ALLOW_UNSUPPORTED_COMPILER)
      message(WARNING "${msg} Continuing because ACME_ALLOW_UNSUPPORTED_COMPILER=ON; C++23 support may be incomplete.")
    else()
      message(FATAL_ERROR "${msg} Install a supported compiler (see .tool-versions) or configure with -DACME_ALLOW_UNSUPPORTED_COMPILER=ON.")
    endif()
  endif()
endfunction()
