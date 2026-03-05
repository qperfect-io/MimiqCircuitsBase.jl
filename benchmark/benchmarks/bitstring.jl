#
# Copyright © 2025-2026 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ==================== #
# BITSTRING BENCHMARKS #
# ==================== #

SUITE["bitstring"] = BenchmarkGroup(["Benchmarks for BitString operations"])

# Creation
SUITE["bitstring"]["create"] = BenchmarkGroup()
SUITE["bitstring"]["create"]["from_int_8"] = @benchmarkable BitString(8, 42)
SUITE["bitstring"]["create"]["from_int_16"] = @benchmarkable BitString(16, 1234)
SUITE["bitstring"]["create"]["from_int_64"] = @benchmarkable BitString(64, 12345678)
SUITE["bitstring"]["create"]["from_str_8"] = @benchmarkable parse(BitString, "10101010")
SUITE["bitstring"]["create"]["from_str_16"] = @benchmarkable parse(BitString, "1010101010101010")

# Operations
bs1 = BitString(16, 42)
bs2 = BitString(16, 123)
bs_large1 = BitString(64, 12345)
bs_large2 = BitString(64, 67890)

SUITE["bitstring"]["ops"] = BenchmarkGroup()
SUITE["bitstring"]["ops"]["xor_16"] = @benchmarkable $bs1 ⊻ $bs2
SUITE["bitstring"]["ops"]["and_16"] = @benchmarkable $bs1 & $bs2
SUITE["bitstring"]["ops"]["or_16"] = @benchmarkable $bs1 | $bs2
SUITE["bitstring"]["ops"]["xor_64"] = @benchmarkable $bs_large1 ⊻ $bs_large2
SUITE["bitstring"]["ops"]["to_int_16"] = @benchmarkable bitstring_to_integer($bs1)
SUITE["bitstring"]["ops"]["to_int_64"] = @benchmarkable bitstring_to_integer($bs_large1)
SUITE["bitstring"]["ops"]["getindex"] = @benchmarkable $bs1[5]
SUITE["bitstring"]["ops"]["length"] = @benchmarkable length($bs_large1)
