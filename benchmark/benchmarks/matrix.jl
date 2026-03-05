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

# ============================= #
# MATRIX COMPUTATION BENCHMARKS #
# ============================= #

SUITE["matrix"] = BenchmarkGroup(["Benchmarks for unitary matrix computation"])

# Single gate matrices
SUITE["matrix"]["single"] = BenchmarkGroup()

single_gates = [
    ("H", GateH()),
    ("X", GateX()),
    ("Y", GateY()),
    ("Z", GateZ()),
    ("S", GateS()),
    ("T", GateT()),
    ("SX", GateSX()),
    ("RX", GateRX(0.123)),
    ("RY", GateRY(0.123)),
    ("RZ", GateRZ(0.123)),
    ("P", GateP(0.123)),
    ("U1", GateU1(0.123)),
    ("U2", GateU2(0.123, 0.234)),
    ("U3", GateU(0.123, 0.234, 0.345)),
]

for (name, gate) in single_gates
    SUITE["matrix"]["single"][name] = @benchmarkable matrix($gate)
end

# Two-qubit gate matrices
SUITE["matrix"]["two_qubit"] = BenchmarkGroup()

two_qubit_gates = [
    ("CX", GateCX()),
    ("CY", GateCY()),
    ("CZ", GateCZ()),
    ("CH", GateCH()),
    ("SWAP", GateSWAP()),
    ("ISWAP", GateISWAP()),
    ("CS", GateCS()),
    ("CP", GateCP(0.123)),
    ("CRX", GateCRX(0.123)),
    ("CRY", GateCRY(0.123)),
    ("CRZ", GateCRZ(0.123)),
    ("RXX", GateRXX(0.123)),
    ("RYY", GateRYY(0.123)),
    ("RZZ", GateRZZ(0.123)),
    ("DCX", GateDCX()),
    ("ECR", GateECR()),
]

for (name, gate) in two_qubit_gates
    SUITE["matrix"]["two_qubit"][name] = @benchmarkable matrix($gate)
end

# Three-qubit gate matrices
SUITE["matrix"]["three_qubit"] = BenchmarkGroup()

three_qubit_gates = [
    ("CCX", GateCCX()),
    ("CSWAP", GateCSWAP()),
    ("CCZ", control(1, GateCZ())),
]

for (name, gate) in three_qubit_gates
    SUITE["matrix"]["three_qubit"][name] = @benchmarkable matrix($gate)
end

# Circuit matrices
SUITE["matrix"]["circuit"] = BenchmarkGroup()

for n in [2, 3, 4, 5, 6]
    ghz = ghz_circuit(n)
    SUITE["matrix"]["circuit"]["ghz_$n"] = @benchmarkable matrix($ghz)
end

for n in [2, 3, 4, 5]
    qft = qft_circuit(n)
    SUITE["matrix"]["circuit"]["qft_$n"] = @benchmarkable matrix($qft)
end
