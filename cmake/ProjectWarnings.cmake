# Warning sets from the PRD quality-gate table. -Werror / /WX is opt-in so a
# local build never fails on a new compiler's new warning; CI turns it on.
set(ACME_WARNINGS_GCC_CLANG
  -Wall
  -Wextra
  -Wpedantic
  -Wshadow
  -Wconversion
  -Wsign-conversion
  -Wnon-virtual-dtor
  -Wold-style-cast
  -Wimplicit-fallthrough
  -Wcast-align
  -Wunused
  -Woverloaded-virtual
  -Wdouble-promotion
  -Wformat=2)

# GCC-only: Clang has no -Wnull-dereference and warns about the unknown flag.
set(ACME_WARNINGS_GCC_ONLY
  -Wnull-dereference
  -Wduplicated-cond
  -Wduplicated-branches
  -Wlogical-op
  -Wuseless-cast)

set(ACME_WARNINGS_MSVC
  /W4
  /permissive-
  /Zc:__cplusplus
  /Zc:preprocessor
  /utf-8
  /w14242  # conversion, possible loss of data
  /w14263  # member function does not override any base class virtual
  /w14265  # class has virtual functions but non-virtual destructor
  /w14287  # unsigned/negative constant mismatch
  /w14296  # expression is always false
  /w14545  # expression before comma evaluates to a function missing arguments
  /w14640  # thread-unsafe static member initialisation
  /w14826  # conversion is sign-extended
  /w14928) # illegal copy-initialisation

function(acme_apply_warnings target)
  if(MSVC)
    set(flags ${ACME_WARNINGS_MSVC})
    if(ACME_WARNINGS_AS_ERRORS)
      list(APPEND flags /WX)
    endif()
  else()
    set(flags ${ACME_WARNINGS_GCC_CLANG})
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      list(APPEND flags ${ACME_WARNINGS_GCC_ONLY})
    endif()
    if(ACME_WARNINGS_AS_ERRORS)
      list(APPEND flags -Werror)
    endif()
  endif()
  target_compile_options(${target} INTERFACE ${flags})
endfunction()
