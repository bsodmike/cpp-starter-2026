#pragma once

#include <string_view>

namespace acme::core {

struct version_info {
  int major{};
  int minor{};
  int patch{};
};

[[nodiscard]] version_info version() noexcept;

[[nodiscard]] std::string_view version_string() noexcept;

}  // namespace acme::core
