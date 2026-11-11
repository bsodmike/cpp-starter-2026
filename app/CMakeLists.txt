add_executable(acme_app main.cpp)

target_link_libraries(acme_app
  PRIVATE
    acme::core
    acme::options
    $<BUILD_INTERFACE:acme::build_options>)

set_target_properties(acme_app PROPERTIES
  OUTPUT_NAME acme
  INTERPROCEDURAL_OPTIMIZATION ${ACME_IPO_ENABLED})
