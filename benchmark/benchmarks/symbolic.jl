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
# SYMBOLIC OPERATIONS BENCHMARKS #
# ============================== #

if HAS_SYMBOLICS
    SUITE["symbolic"] = BenchmarkGroup(["Benchmarks for symbolic/parametric operations"])

    # Gate creation with symbols
    SUITE["symbolic"]["create"] = BenchmarkGroup()
    SUITE["symbolic"]["create"]["RX_sym"] = @benchmarkable GateRX($θ)
    SUITE["symbolic"]["create"]["RY_sym"] = @benchmarkable GateRY($θ)
    SUITE["symbolic"]["create"]["RZ_sym"] = @benchmarkable GateRZ($θ)
    SUITE["symbolic"]["create"]["U3_sym"] = @benchmarkable GateU($θ, $ϕ, $λ)

    # issymbolic checks
    SUITE["symbolic"]["issymbolic"] = BenchmarkGroup()

    sym_rx = GateRX(θ)
    num_rx = GateRX(0.5)
    sym_circuit = symbolic_variational_ansatz(4, 2)
    num_circuit = variational_ansatz(4, 2)

    SUITE["symbolic"]["issymbolic"]["sym_gate"] = @benchmarkable issymbolic($sym_rx)
    SUITE["symbolic"]["issymbolic"]["num_gate"] = @benchmarkable issymbolic($num_rx)
    SUITE["symbolic"]["issymbolic"]["sym_circuit"] = @benchmarkable issymbolic($sym_circuit)
    SUITE["symbolic"]["issymbolic"]["num_circuit"] = @benchmarkable issymbolic($num_circuit)

    # evaluate
    SUITE["symbolic"]["evaluate"] = BenchmarkGroup()
    param_dict = Dict(θ => 0.5, ϕ => 0.3, λ => 0.1)

    SUITE["symbolic"]["evaluate"]["RX"] = @benchmarkable evaluate($sym_rx, $param_dict)

    sym_u3 = GateU(θ, ϕ, λ)
    SUITE["symbolic"]["evaluate"]["U3"] = @benchmarkable evaluate($sym_u3, $param_dict)
end
