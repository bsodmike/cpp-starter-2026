#include <acme/core/text.hpp>
#include <acme/core/version.hpp>

#include <iostream>
#include <string_view>

int main() {
  if (acme::core::trim("  ok  ") != "ok") {
    std::cerr << "trim() misbehaved in the installed package\n";
    return 1;
  }

  const auto parsed = acme::core::parse_int("21");
  if (!parsed || *parsed != 21) {
    std::cerr << "parse_int() misbehaved in the installed package\n";
    return 1;
  }

  std::cout << "consumed acme " << acme::core::version_string() << '\n';
  return 0;
}
