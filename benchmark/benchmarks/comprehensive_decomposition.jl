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

# ====================================== #
# COMPREHENSIVE DECOMPOSITION BENCHMARKS #
# ====================================== #

SUITE["decomposition"]["bases"] = BenchmarkGroup()
SUITE["decomposition"]["bases"]["Canonical"] = BenchmarkGroup()
SUITE["decomposition"]["bases"]["OpenQASM"] = BenchmarkGroup()
SUITE["decomposition"]["bases"]["CliffordT"] = BenchmarkGroup()

# Helper to add basis benchmarks for a circuit
function add_decomp_benchmarks(name, circuit)
    SUITE["decomposition"]["bases"]["Canonical"][name] = @benchmarkable decompose($circuit, basis=CanonicalBasis())
    SUITE["decomposition"]["bases"]["OpenQASM"][name] = @benchmarkable decompose($circuit, basis=QASMBasis())
    # Note: CliffordT decomposition might fail for non-Clifford+T circuits depending on implementation
    SUITE["decomposition"]["bases"]["CliffordT"][name] = @benchmarkable decompose($circuit, basis=CliffordTBasis())
end

for n in [4, 8]
    add_decomp_benchmarks("qft_n$n", qft_circuit(n))
    add_decomp_benchmarks("random_n$n", random_circuit(n, 10)) # depth 10
    add_decomp_benchmarks("qaoa_n$n", qaoa_complete_graph(n, 1))
    add_decomp_benchmarks("trotter_n$n", trotter_heisenberg_circuit(n, 5, 0.1))
    add_decomp_benchmarks("grover_n$n", grover_circuit(n, 1, BitString(n, 1)))
end
