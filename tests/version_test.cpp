#include <acme/core/version.hpp>

#include <gtest/gtest.h>

#include <format>

namespace {

TEST(Version, ComponentsAreNonNegative) {
  const auto info = acme::core::version();
  EXPECT_GE(info.major, 0);
  EXPECT_GE(info.minor, 0);
  EXPECT_GE(info.patch, 0);
}

TEST(Version, StringMatchesComponents) {
  const auto info = acme::core::version();
  const auto expected = std::format("{}.{}.{}", info.major, info.minor, info.patch);
  EXPECT_EQ(acme::core::version_string(), expected);
}

}  // namespace
