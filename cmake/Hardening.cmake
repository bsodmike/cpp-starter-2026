# Release hardening per the OpenSSF Compiler Options Hardening Guide for C/C++.
# Every flag is probed before use: the guide's set is architecture- and
# version-dependent (-fcf-protection is x86-only, -mbranch-protection arm64-only,
# -fhardened is GCC 14+), so probing keeps one preset working everywhere.
include(CheckCXXCompilerFlag)
include(CheckLinkerFlag)

function(acme_try_compile_flag flag out_var)
  string(MAKE_C_IDENTIFIER "ACME_HAS_CXX${flag}" cache_var)
  check_cxx_compiler_flag("${flag}" ${cache_var})
  if(${cache_var})
    set(${out_var} "${flag}" PARENT_SCOPE)
  else()
    set(${out_var} "" PARENT_SCOPE)
  endif()
endfunction()

function(acme_try_link_flag flag out_var)
  string(MAKE_C_IDENTIFIER "ACME_HASLINK${flag}" cache_var)
  check_linker_flag(CXX "${flag}" ${cache_var})
  if(${cache_var})
    set(${out_var} "${flag}" PARENT_SCOPE)
  else()
    set(${out_var} "" PARENT_SCOPE)
  endif()
endfunction()

# Standard-library assertions. Kept on in debug and in release (fast mode), as
# the PRD requires; these are ABI-affecting for libc++ so consumers of an
# installed ACME see the same mode via the exported options target.
function(acme_apply_library_hardening target)
  if(NOT ACME_ENABLE_LIBRARY_HARDENING)
    return()
  endif()

  if(MSVC)
    # MSVC Debug already defaults to _ITERATOR_DEBUG_LEVEL=2; leaving it at the
    # default keeps the ABI consistent with prebuilt vcpkg binaries.
    return()
  endif()

  target_compile_definitions(${target} INTERFACE
    $<$<CXX_COMPILER_ID:GNU>:_GLIBCXX_ASSERTIONS>
    $<$<CXX_COMPILER_ID:Clang,AppleClang>:_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST>)
endfunction()

function(acme_apply_hardening target)
  if(NOT ACME_ENABLE_HARDENING)
    return()
  endif()

  if(MSVC)
    target_compile_options(${target} INTERFACE /sdl /guard:cf /Qspectre)
    target_link_options(${target} INTERFACE
      /guard:cf /CETCOMPAT /DYNAMICBASE /HIGHENTROPYVA /NXCOMPAT)
    return()
  endif()

  set(compile_flags "")
  set(link_flags "")

  # GCC 14+ umbrella flag; it subsumes _FORTIFY_SOURCE, stack protector,
  # stack-clash and branch protection, so only probe the rest when absent.
  acme_try_compile_flag(-fhardened have_fhardened)
  if(have_fhardened)
    list(APPEND compile_flags ${have_fhardened})
  else()
    foreach(flag -fstack-protector-strong -fstack-clash-protection
                 -fcf-protection=full -mbranch-protection=standard
                 -ftrivial-auto-var-init=zero)
      acme_try_compile_flag(${flag} found)
      if(found)
        list(APPEND compile_flags ${found})
      endif()
    endforeach()
    # _FORTIFY_SOURCE needs optimisation; defining it at -O0 only warns.
    target_compile_definitions(${target} INTERFACE
      $<$<NOT:$<CONFIG:Debug>>:_FORTIFY_SOURCE=3>)
  endif()

  foreach(flag -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,-z,nodlopen)
    acme_try_link_flag(${flag} found)
    if(found)
      list(APPEND link_flags ${found})
    endif()
  endforeach()

  if(compile_flags)
    target_compile_options(${target} INTERFACE ${compile_flags})
  endif()
  if(link_flags)
    target_link_options(${target} INTERFACE ${link_flags})
  endif()
endfunction()
