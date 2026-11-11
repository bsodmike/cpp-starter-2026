#include <acme/core/text.hpp>
#include <acme/core/version.hpp>

#include <cstdlib>
#include <exception>
#include <format>
#include <iostream>
#include <span>
#include <string_view>

namespace {

int print_usage(std::string_view program) {
  std::cout << std::format("usage: {} <integer> [<integer>...]\n", program);
  return EXIT_FAILURE;
}

int run(int argc, char** argv) {
  const std::span args{argv, static_cast<std::size_t>(argc)};
  const std::string_view program = args.empty() ? "acme" : args[0];

  if (args.size() < 2) {
    return print_usage(program);
  }

  std::cout << std::format("acme {}\n", acme::core::version_string());

  long long total = 0;
  for (const auto* arg : args.subspan(1)) {
    const auto parsed = acme::core::parse_int(arg);
    if (!parsed) {
      std::cerr << std::format("error: '{}': {}\n", arg, acme::core::describe(parsed.error()));
      return EXIT_FAILURE;
    }
    total += *parsed;
  }

  std::cout << std::format("sum = {}\n", total);
  return EXIT_SUCCESS;
}

}  // namespace

int main(int argc, char** argv) {
  // std::format and the iostreams can throw; letting that escape main loses the
  // diagnostic and the exit code.
  try {
    return run(argc, argv);
  } catch (const std::exception& error) {
    std::cerr << "fatal: " << error.what() << '\n';
    return EXIT_FAILURE;
  } catch (...) {
    std::cerr << "fatal: unknown error\n";
    return EXIT_FAILURE;
  }
}
