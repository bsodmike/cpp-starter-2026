#include <acme/core/text.hpp>

#include <benchmark/benchmark.h>

#include <string>

namespace {

void BM_ParseInt(benchmark::State& state) {
  const std::string input = "  1234567 ";
  for (auto _ : state) {
    benchmark::DoNotOptimize(acme::core::parse_int(input));
  }
}

BENCHMARK(BM_ParseInt);

void BM_Split(benchmark::State& state) {
  const std::string input = "alpha,beta,gamma,delta,epsilon";
  for (auto _ : state) {
    benchmark::DoNotOptimize(acme::core::split(input, ','));
  }
}

BENCHMARK(BM_Split);

}  // namespace
