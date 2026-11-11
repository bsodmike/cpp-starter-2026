#pragma once

#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <vector>

namespace acme::core {

enum class parse_error : std::uint8_t {
  empty,
  not_a_number,
  out_of_range,
};

[[nodiscard]] std::string_view trim(std::string_view input) noexcept;

[[nodiscard]] std::vector<std::string_view> split(std::string_view input, char delimiter);

[[nodiscard]] std::string to_lower(std::string_view input);

// Returns the parsed value, or the reason it could not be parsed. Leading and
// trailing whitespace is accepted; anything else in the string is an error.
[[nodiscard]] std::expected<long long, parse_error> parse_int(std::string_view input);

[[nodiscard]] std::string_view describe(parse_error error) noexcept;

}  // namespace acme::core
