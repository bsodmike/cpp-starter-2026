// Deliberate signed integer overflow. UBSan must report it; see
// tests/cmake/expect_sanitizer_failure.cmake.
#include <iostream>
#include <limits>

int main(int argc, char** /*argv*/) {
  int value = std::numeric_limits<int>::max();
  std::cout << "adding " << argc << " to " << value << '\n';

  value += argc;  // argc is at least 1, so this always overflows.
  std::cout << "result " << value << '\n';
  return value;
}
