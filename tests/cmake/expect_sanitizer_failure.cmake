# Runs TEST_COMMAND and passes only when it fails *and* the failure came from a
# sanitizer, matched against EXPECT_PATTERN. WILL_FAIL alone would also accept a
# binary that failed to launch, which would quietly hide a broken sanitizer
# build. Driven through cmake -P so it works identically on all three OSes.
if(NOT DEFINED TEST_COMMAND OR NOT DEFINED EXPECT_PATTERN)
  message(FATAL_ERROR "TEST_COMMAND and EXPECT_PATTERN are required.")
endif()

execute_process(
  COMMAND "${TEST_COMMAND}"
  RESULT_VARIABLE exit_code
  OUTPUT_VARIABLE stdout
  ERROR_VARIABLE stderr)

set(output "${stdout}${stderr}")

if(exit_code EQUAL 0)
  message(FATAL_ERROR
    "Expected '${TEST_COMMAND}' to be stopped by a sanitizer, but it exited 0.\n"
    "Output:\n${output}")
endif()

if(NOT output MATCHES "${EXPECT_PATTERN}")
  message(FATAL_ERROR
    "'${TEST_COMMAND}' failed with code ${exit_code}, but the output did not match "
    "'${EXPECT_PATTERN}', so the failure was not a sanitizer diagnostic.\n"
    "Output:\n${output}")
endif()

message(STATUS "Sanitizer correctly reported: ${EXPECT_PATTERN}")
