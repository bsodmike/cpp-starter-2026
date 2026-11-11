#include <acme/core/text.hpp>

#include <algorithm>
#include <cctype>
#include <charconv>
#include <iterator>
#include <system_error>

namespace acme::core {
namespace {

constexpr std::string_view whitespace = " \t\n\r\f\v";

}  // namespace

std::string_view trim(std::string_view input) noexcept {
  const auto first = input.find_first_not_of(whitespace);
  if (first == std::string_view::npos) {
    return {};
  }
  const auto last = input.find_last_not_of(whitespace);
  // Built directly rather than with substr(), which is not noexcept: the
  // indices are already known good, but the compiler cannot see that.
  return {input.data() + first, last - first + 1};
}

std::vector<std::string_view> split(std::string_view input, char delimiter) {
  std::vector<std::string_view> parts;
  if (input.empty()) {
    return parts;
  }

  std::size_t start = 0;
  while (true) {
    const auto pos = input.find(delimiter, start);
    if (pos == std::string_view::npos) {
      parts.push_back(input.substr(start));
      return parts;
    }
    parts.push_back(input.substr(start, pos - start));
    start = pos + 1;
  }
}

std::string to_lower(std::string_view input) {
  std::string out;
  out.reserve(input.size());
  std::ranges::transform(input, std::back_inserter(out), [](char c) {
    const auto uc = static_cast<unsigned char>(c);
    return static_cast<char>(std::tolower(static_cast<int>(uc)));
  });
  return out;
}

std::expected<long long, parse_error> parse_int(std::string_view input) {
  const auto text = trim(input);
  if (text.empty()) {
    return std::unexpected(parse_error::empty);
  }

  long long value = 0;
  const auto* const begin = text.data();
  const auto* const end = begin + text.size();
  const auto result = std::from_chars(begin, end, value);

  if (result.ec == std::errc::result_out_of_range) {
    return std::unexpected(parse_error::out_of_range);
  }
  if (result.ec != std::errc{} || result.ptr != end) {
    return std::unexpected(parse_error::not_a_number);
  }
  return value;
}

std::string_view describe(parse_error error) noexcept {
  switch (error) {
    case parse_error::empty:
      return "input was empty";
    case parse_error::not_a_number:
      return "input was not a number";
    case parse_error::out_of_range:
      return "value did not fit in long long";
  }
  return "unknown error";
}

}  // namespace acme::core
