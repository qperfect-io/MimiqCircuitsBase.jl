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
# ADVANCED CIRCUIT BENCHMARKS #
# =========================== #

SUITE["construction"]["advanced"] = BenchmarkGroup()

for n in [4, 8, 12]
    SUITE["construction"]["advanced"]["wstate_n$n"] = @benchmarkable wstate_circuit($n)
    SUITE["construction"]["advanced"]["graph_state_linear_n$n"] = @benchmarkable graph_state_linear($n)
    SUITE["construction"]["advanced"]["graph_state_complete_n$n"] = @benchmarkable graph_state_complete($n)

    # QAOA
    SUITE["construction"]["advanced"]["qaoa_complete_n$n"] = @benchmarkable qaoa_complete_graph($n, 2)

    # Trotter
    SUITE["construction"]["advanced"]["trotter_heisenberg_n$n"] = @benchmarkable trotter_heisenberg_circuit($n, 10, 0.1)

    # IQP
    SUITE["construction"]["advanced"]["iqp_random_n$n"] = @benchmarkable iqp_random_circuit($n)

    # Swap Network
    SUITE["construction"]["advanced"]["swap_network_n$n"] = @benchmarkable swap_network_circuit($n)
end

# Fixed size
SUITE["construction"]["advanced"]["bricklayer_10x10"] = @benchmarkable bricklayer_circuit(10, 10)
SUITE["construction"]["advanced"]["grid_4x4x10"] = @benchmarkable grid_circuit(4, 4, 10)
SUITE["construction"]["advanced"]["grover_n4"] = @benchmarkable grover_circuit(4, 2, BitString(4, 1))
SUITE["construction"]["advanced"]["qpe_n4"] = @benchmarkable qpe_circuit(4)
SUITE["construction"]["advanced"]["fermionic_n6_l3"] = @benchmarkable fermionic_swap_circuit(6, 3)
SUITE["construction"]["advanced"]["tree_depth4"] = @benchmarkable tree_circuit(4)
