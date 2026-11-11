// Deliberate heap-buffer-overflow. ASan must report it; see
// tests/cmake/expect_sanitizer_failure.cmake.
#include <cstddef>
#include <iostream>
#include <vector>

int main(int argc, char** /*argv*/) {
  std::vector<int> buffer(4, 1);

  // Derived from argc so no compiler can fold the access away or prove it UB
  // at compile time.
  const std::size_t index = buffer.size() + static_cast<std::size_t>(argc) - 1;
  std::cout << "reading index " << index << " of " << buffer.size() << '\n';

  // data()[] on purpose, not operator[]: library hardening bounds-checks
  // operator[] and would abort with a libc++/libstdc++ assertion before ASan
  // ever sees the access, which is not what this test is proving.
  // NOLINTNEXTLINE(readability-simplify-subscript-expr)
  const int value = buffer.data()[index];
  std::cout << "read " << value << '\n';
  return value;
}
