#include <acme/core/version.hpp>

#include <string_view>

namespace acme::core {

version_info version() noexcept {
  return {.major = ACME_VERSION_MAJOR, .minor = ACME_VERSION_MINOR, .patch = ACME_VERSION_PATCH};
}

std::string_view version_string() noexcept {
  return ACME_VERSION_STRING;
}

}  // namespace acme::core
