# ASan + UBSan for dev and CI debug builds; TSan is nightly-only and cannot be
# combined with ASan.
function(acme_apply_sanitizers target)
  if(ACME_ENABLE_SANITIZERS AND ACME_ENABLE_TSAN)
    message(FATAL_ERROR "ACME_ENABLE_SANITIZERS and ACME_ENABLE_TSAN are mutually exclusive.")
  endif()

  if(NOT ACME_ENABLE_SANITIZERS AND NOT ACME_ENABLE_TSAN)
    return()
  endif()

  if(MSVC)
    if(ACME_ENABLE_TSAN)
      message(FATAL_ERROR "MSVC has no ThreadSanitizer.")
    endif()
    # MSVC ships ASan only; UBSan is unavailable. /RTC conflicts with ASan.
    target_compile_options(${target} INTERFACE /fsanitize=address /Oy-)
    target_link_options(${target} INTERFACE /INCREMENTAL:NO)
    return()
  endif()

  if(ACME_ENABLE_TSAN)
    set(flags -fsanitize=thread -fno-omit-frame-pointer)
  else()
    set(flags -fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined)
  endif()

  target_compile_options(${target} INTERFACE ${flags} -g)
  target_link_options(${target} INTERFACE ${flags})
endfunction()
