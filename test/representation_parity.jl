#
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
# Representation choices shared with mimiqcircuits (Python), which carries the
# same cases in tests/test_representation_parity.py.

using Test
using MimiqCircuitsBase
using Symbolics
const MCB = MimiqCircuitsBase

@testset "getparams of Repeat forwards to the wrapped operation" begin
    @test collect(getparams(Repeat(3, GateRX(0.2)))) == [0.2]
    @test parnames(Repeat(3, GateRX(0.2))) == (:θ,)
end

@testset "Operators that are not gates cannot be pushed" begin
    for op in (Projector0(), SigmaMinus(), DiagonalOp(1, 0.5), RescaledGate(GateX(), 0.5))
        @test_throws ArgumentError push!(Circuit(), op, 1)
    end
end

@testset "Float exponents that are exact fractions become fractions" begin
    @test Power(GateX(), 0.5) isa GateSX
    @test Power(GateZ(), 0.25) isa GateT
    @test GateX()^0.5 isa GateSX
    @test Power(GateCX(), 0.5) == Power(GateCX(), 1 // 2)
    @test Power(GateX(), 2.0) == Power(GateX(), 2)
    # Not a fraction with a small denominator: kept as it is.
    @test Power(GateX(), sqrt(2)) isa Power{sqrt(2)}
    @test Power(GateCX(), 1 / 3) == Power(GateCX(), 1 // 3)
    @test Power(GateCX(), 0.001) == Power(GateCX(), 1 // 1000)
    @test Power(GateX(), 1e20) isa Power{1e20}
end

@testset "Inverse of GateU does not produce a negative zero" begin
    g = inverse(GateU(0.1, 0.0, 0.3))
    @test !signbit(Symbolics.value(g.λ))
    @test !signbit(Symbolics.value(g.γ))
end

@testset "Symbolic quotients are serialized as DIV" begin
    @variables x
    arg = MCB.toproto(1 / x)
    @test arg.arg[].mtype == MCB.circuit_pb.FunctionType.DIV
end
