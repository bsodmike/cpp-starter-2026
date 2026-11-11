#include <acme/core/text.hpp>

#include <gtest/gtest.h>

#include <limits>
#include <string>
#include <string_view>

namespace {

using acme::core::parse_error;

TEST(Trim, RemovesSurroundingWhitespace) {
  EXPECT_EQ(acme::core::trim("  hello \t\n"), "hello");
  EXPECT_EQ(acme::core::trim("hello"), "hello");
}

TEST(Trim, AllWhitespaceBecomesEmpty) {
  EXPECT_TRUE(acme::core::trim(" \t\r\n").empty());
  EXPECT_TRUE(acme::core::trim("").empty());
}

TEST(Split, SplitsOnDelimiter) {
  const auto parts = acme::core::split("a,b,c", ',');
  ASSERT_EQ(parts.size(), 3U);
  EXPECT_EQ(parts[0], "a");
  EXPECT_EQ(parts[1], "b");
  EXPECT_EQ(parts[2], "c");
}

TEST(Split, KeepsEmptyFields) {
  const auto parts = acme::core::split("a,,c", ',');
  ASSERT_EQ(parts.size(), 3U);
  EXPECT_TRUE(parts[1].empty());
}

TEST(Split, EmptyInputYieldsNoParts) {
  EXPECT_TRUE(acme::core::split("", ',').empty());
}

TEST(ToLower, LowercasesAscii) {
  EXPECT_EQ(acme::core::to_lower("AbC-123"), "abc-123");
}

TEST(ParseInt, ParsesDecimal) {
  const auto value = acme::core::parse_int("42");
  ASSERT_TRUE(value.has_value());
  EXPECT_EQ(*value, 42);
}

TEST(ParseInt, AcceptsSurroundingWhitespaceAndSign) {
  EXPECT_EQ(acme::core::parse_int("  -7 ").value(), -7);
}

TEST(ParseInt, RejectsEmpty) {
  const auto value = acme::core::parse_int("   ");
  ASSERT_FALSE(value.has_value());
  EXPECT_EQ(value.error(), parse_error::empty);
}

TEST(ParseInt, RejectsTrailingGarbage) {
  const auto value = acme::core::parse_int("12abc");
  ASSERT_FALSE(value.has_value());
  EXPECT_EQ(value.error(), parse_error::not_a_number);
}

TEST(ParseInt, ReportsOutOfRange) {
  const auto too_big = std::to_string(std::numeric_limits<long long>::max()) + "0";
  const auto value = acme::core::parse_int(too_big);
  ASSERT_FALSE(value.has_value());
  EXPECT_EQ(value.error(), parse_error::out_of_range);
}

TEST(Describe, CoversEveryError) {
  for (const auto error :
       {parse_error::empty, parse_error::not_a_number, parse_error::out_of_range}) {
    EXPECT_FALSE(acme::core::describe(error).empty());
  }
}

}  // namespace
