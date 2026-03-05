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

# ============================== #
# GATE TRANSFORMATION BENCHMARKS #
# ============================== #

SUITE["transforms"] = BenchmarkGroup(["Benchmarks for gate transformations (inverse, power, control)"])

# --- inverse ---
SUITE["transforms"]["inverse"] = BenchmarkGroup()

inv_gates = [
    ("H", GateH()),
    ("S", GateS()),
    ("T", GateT()),
    ("RX", GateRX(0.5)),
    ("U", GateU(0.1, 0.2, 0.3)),
    ("CX", GateCX()),
    ("SWAP", GateSWAP()),
    ("CCX", GateCCX()),
]

for (name, gate) in inv_gates
    SUITE["transforms"]["inverse"]["gate_$name"] = @benchmarkable inverse($gate)
end

for n in [10, 50, 100]
    circ = random_unitary_circuit(10, n)
    SUITE["transforms"]["inverse"]["circuit_n$n"] = @benchmarkable inverse($circ)
end

# --- power ---
SUITE["transforms"]["power"] = BenchmarkGroup()

SUITE["transforms"]["power"]["T_pow2"] = @benchmarkable power(GateT(), 2)
SUITE["transforms"]["power"]["S_pow4"] = @benchmarkable power(GateS(), 4)
SUITE["transforms"]["power"]["X_pow0.5"] = @benchmarkable power(GateX(), 0.5)
SUITE["transforms"]["power"]["RX_pow3"] = @benchmarkable power(GateRX(0.5), 3)
SUITE["transforms"]["power"]["CX_pow2"] = @benchmarkable power(GateCX(), 2)

# --- control ---
SUITE["transforms"]["control"] = BenchmarkGroup()

SUITE["transforms"]["control"]["X_c1"] = @benchmarkable control(1, GateX())
SUITE["transforms"]["control"]["X_c2"] = @benchmarkable control(2, GateX())
SUITE["transforms"]["control"]["H_c1"] = @benchmarkable control(1, GateH())
SUITE["transforms"]["control"]["RX_c1"] = @benchmarkable control(1, GateRX(0.5))
SUITE["transforms"]["control"]["SWAP_c1"] = @benchmarkable control(1, GateSWAP())
SUITE["transforms"]["control"]["CX_c1"] = @benchmarkable control(1, GateCX())  # CCX

# --- remove_unused ---
SUITE["transforms"]["remove_unused"] = BenchmarkGroup()

for n in [10, 100, 1000]
    # 0% unused (all used)
    SUITE["transforms"]["remove_unused"]["used_all_n$n"] = @benchmarkable begin
        c = Circuit()
        push!(c, GateH(), 1:$n)
        remove_unused(c)
    end

    # 50% unused
    SUITE["transforms"]["remove_unused"]["used_50pct_n$n"] = @benchmarkable begin
        c = Circuit()
        push!(c, GateH(), 1:2:$n)
        remove_unused(c)
    end

    # 90% unused (only 10% used)
    SUITE["transforms"]["remove_unused"]["used_10pct_n$n"] = @benchmarkable begin
        c = Circuit()
        indices = 1:10:$n
        if isempty(indices)
            push!(c, GateH(), 1)
        else
            push!(c, GateH(), indices)
        end
        remove_unused(c)
    end
end

# --- remove_swaps ---
SUITE["transforms"]["remove_swaps"] = BenchmarkGroup()

for n in [10, 50, 100]
    # Random swaps
    SUITE["transforms"]["remove_swaps"]["random_n$n"] = @benchmarkable begin
        # 40% 1-qubit (H), 60% 2-qubit (SWAP, CX)
        # 2-qubit pool will have SWAP and CX, so 50/50 split between them -> 30% each overall
        c = random_circuit($n, $n;
            gate_filter=g -> g in (GateSWAP, GateCX, GateH),
            weights=(0.4, 0.6, 0.0, 0.0)
        )
        remove_swaps(c)
    end

    # Swap network (heavy usage of swaps)
    SUITE["transforms"]["remove_swaps"]["swap_network_n$n"] = @benchmarkable begin
        c = swap_network_circuit($n)
        remove_swaps(c)
    end

    # Fermionic swap network (uses fSWAP-like structures)
    # n_layers = n to match roughly O(n^2) depth or similar
    SUITE["transforms"]["remove_swaps"]["fermionic_swap_n$n"] = @benchmarkable begin
        c = fermionic_swap_circuit($n, $n)
        remove_swaps(c)
    end
end

