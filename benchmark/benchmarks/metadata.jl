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

# =========================== #
# CIRCUIT METADATA BENCHMARKS #
# =========================== #

SUITE["metadata"] = BenchmarkGroup(["Benchmarks for circuit property queries"])

for n in [10, 50, 100]
    circuit = random_circuit(50, n)

    SUITE["metadata"]["numqubits_n$n"] = @benchmarkable numqubits($circuit)
    SUITE["metadata"]["numbits_n$n"] = @benchmarkable numbits($circuit)
    SUITE["metadata"]["length_n$n"] = @benchmarkable length($circuit)
    SUITE["metadata"]["isempty_n$n"] = @benchmarkable isempty($circuit)
    SUITE["metadata"]["depth_n$n"] = @benchmarkable depth($circuit)
end
