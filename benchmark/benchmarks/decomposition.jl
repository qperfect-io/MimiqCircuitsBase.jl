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

# ======================== #
# DECOMPOSITION BENCHMARKS #
# ======================== #

SUITE["decomposition"] = BenchmarkGroup(["Benchmarks for gate and circuit decomposition"])

# Single gate decomposition
SUITE["decomposition"]["gate"] = BenchmarkGroup()

decomp_gates = [
    ("H", GateH()),
    ("S", GateS()),
    ("T", GateT()),
    ("RX", GateRX(0.123)),
    ("RY", GateRY(0.123)),
    ("RZ", GateRZ(0.123)),
    ("CZ", GateCZ()),
    ("SWAP", GateSWAP()),
    ("ISWAP", GateISWAP()),
    ("CCX", GateCCX()),
    ("CSWAP", GateCSWAP()),
    ("CP", GateCP(0.123)),
    ("CRX", GateCRX(0.123)),
    ("CRY", GateCRY(0.123)),
    ("CRZ", GateCRZ(0.123)),
    ("RXX", GateRXX(0.123)),
    ("RYY", GateRYY(0.123)),
    ("RZZ", GateRZZ(0.123)),
    ("DCX", GateDCX()),
    ("ECR", GateECR()),
    ("C9X", control(9, GateX())),
    ("C11H", control(11, GateH())),
    ("C13U", control(13, GateU(0.123, 0.234, 0.345))),
    ("C15RXX", control(15, GateRXX(0.123))),
]

for (name, gate) in decomp_gates
    SUITE["decomposition"]["gate"][name] = @benchmarkable decompose($gate)
end

# decompose_step (single step)
SUITE["decomposition"]["step"] = BenchmarkGroup()

for (name, gate) in decomp_gates
    SUITE["decomposition"]["step"][name] = @benchmarkable decompose_step($gate)
end

# Circuit decomposition
SUITE["decomposition"]["circuit"] = BenchmarkGroup()

for n in [4, 8, 12, 16]
    qft = qft_circuit(n)
    SUITE["decomposition"]["circuit"]["qft_$n"] = @benchmarkable decompose($qft)
end

for (nq, nl) in [(4, 2), (6, 3), (8, 4), (10, 5)]
    var = variational_ansatz(nq, nl)
    SUITE["decomposition"]["circuit"]["var_$(nq)q_$(nl)l"] = @benchmarkable decompose($var)
end

for n in [10, 50, 100]
    circ = random_circuit(10, n)
    SUITE["decomposition"]["circuit"]["random_n$n"] = @benchmarkable decompose($circ)
end

# Decomposition iterator
SUITE["decomposition"]["iterator"] = BenchmarkGroup()

for n in [4, 8, 12]
    qft = qft_circuit(n)
    SUITE["decomposition"]["iterator"]["qft_$n"] = @benchmarkable begin
        count = 0
        for inst in eachdecomposed($qft)
            count += 1
        end
        count
    end
end
