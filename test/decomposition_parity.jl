#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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
# Decompositions pinned to the same result as mimiqcircuits (Python).
#
# mimiqcircuits carries the same cases in tests/test_decomposition_parity.py
# (with 0-based qubits). A change to one of these decompositions has to be
# made in both packages.

using Test
using MimiqCircuitsBase
using Symbolics: Num

# Angles that are fractions of π are exact, as in Python.
const πn = Num(π)

_inst(op, targets...) = Instruction(op, targets...)

# One step of the canonical rewrite.
const STEP_CASES = [
    GateCS() => [_inst(GateT(), 1), _inst(GateCX(), 1, 2), _inst(GateTDG(), 2),
                 _inst(GateCX(), 1, 2), _inst(GateT(), 2)],
    GateCSDG() => [_inst(GateTDG(), 1), _inst(GateCX(), 1, 2), _inst(GateT(), 2),
                   _inst(GateCX(), 1, 2), _inst(GateTDG(), 2)],
    GateCSX() => [_inst(GateH(), 2), _inst(GateCS(), 1, 2), _inst(GateH(), 2)],
    GateCSXDG() => [_inst(GateH(), 2), _inst(GateCSDG(), 1, 2), _inst(GateH(), 2)],
    GateISWAPDG() => [_inst(GateSDG(), 1), _inst(GateSDG(), 2), _inst(GateH(), 1),
                      _inst(GateCX(), 1, 2), _inst(GateCX(), 2, 1), _inst(GateH(), 2)],
    GateCRX(0.3) => [_inst(GateS(), 2), _inst(GateCX(), 1, 2), _inst(GateU(-0.15, 0, 0), 2),
                     _inst(GateCX(), 1, 2), _inst(GateU(0.15, -πn / 2, 0), 2)],
    MeasureXX() => [_inst(GateCX(), 1, 2), _inst(GateH(), 1), _inst(Measure(), 1, 1),
                    _inst(GateH(), 1), _inst(GateCX(), 1, 2)],
    MeasureYY() => [_inst(GateS(), 1), _inst(GateS(), 2), _inst(GateCX(), 1, 2),
                    _inst(GateH(), 1), _inst(Measure(), 1, 1), _inst(GateH(), 1),
                    _inst(GateCX(), 1, 2), _inst(GateSDG(), 1), _inst(GateSDG(), 2)],
    GateCCP(0.3) => [_inst(GateCP(0.15), 2, 3), _inst(GateCX(), 1, 2), _inst(GateCP(-0.15), 2, 3),
                     _inst(GateCX(), 1, 2), _inst(GateCP(0.15), 1, 3)],
    GateU2(0.3, 0.7) => [_inst(GateU(πn / 2, 0.3, 0.7), 1)],
    QFT(3) => [_inst(GateH(), 3), _inst(GateCP(πn / 2), 2, 3), _inst(GateH(), 2),
               _inst(GateCP(πn / 4), 1, 3), _inst(GateCP(πn / 2), 1, 2), _inst(GateH(), 1)],
    PhaseGradient(3) => [_inst(GateP(πn / 4), 3), _inst(GateP(πn / 2), 2), _inst(GateP(π), 1)],
    # inverse(GateU) negates every parameter; a zero stays +0.0.
    Inverse(GateU(0.3, 0.7, 1.1)) => [_inst(GateU(-0.3, -1.1, -0.7, 0.0), 1)],
    Power(GateCCX(), 1 // 2) => [_inst(Control(2, GateSX()), 1, 2, 3)],
    Control(1, Parallel(2, GateH())) => [_inst(GateCH(), 1, 2), _inst(GateCH(), 1, 3)],
]

@testset "Canonical step matches Python: $(opname(op))" for (op, expected) in STEP_CASES
    got = decompose_step(op)
    @test length(got) == length(expected)
    for (g, e) in zip(got, expected)
        @test g == e
    end
end

# Full decompositions into a basis.
const BASIS_CASES = [
    (MeasureX(), QASMBasis(), [_inst(GateH(), 1), _inst(Measure(), 1, 1), _inst(GateH(), 1)]),
    (GateCP(0.3), QASMBasis(), [_inst(GateU(0, 0, 0.15), 1), _inst(GateCX(), 1, 2),
                                _inst(GateU(0, 0, -0.15), 2), _inst(GateCX(), 1, 2),
                                _inst(GateU(0, 0, 0.15), 2)]),
    (ResetX(), QASMBasis(), [_inst(GateH(), 1), _inst(Reset(), 1), _inst(GateH(), 1)]),
]

@testset "Basis decomposition matches Python: $(opname(op))" for (op, basis, expected) in BASIS_CASES
    c = push!(Circuit(), op, 1:numqubits(op)..., 1:numbits(op)...)
    got = decompose(c; basis=basis)
    @test length(got) == length(expected)
    for (g, e) in zip(got, expected)
        @test g == e
    end
end

@testset "QASMBasis rejects noise" begin
    # OpenQASM 2.0 cannot express a noise channel.
    @test_throws MimiqCircuitsBase.DecompositionError decompose(push!(Circuit(), PauliX(0.1), 1); basis=QASMBasis())
end

@testset "CanonicalRewrite does not depend on a basis" begin
    # ResetX is terminal in CanonicalBasis as a noise channel, but the rule
    # still matches it so that other bases can expand it.
    @test MimiqCircuitsBase.isterminal(CanonicalBasis(), ResetX())
    @test matches(CanonicalRewrite(), ResetX())
    @test matches(CanonicalRewrite(), ResetY())
    @test !matches(CanonicalRewrite(), GateU(0.1, 0.2, 0.3))
    @test !matches(CanonicalRewrite(), GateCX())
end
