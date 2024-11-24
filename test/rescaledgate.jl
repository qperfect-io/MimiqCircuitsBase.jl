#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
using Test

@testset "Constructor" begin
    @test_throws MethodError RescaledGate(Projector0(), 0.5)
    @test_throws ArgumentError RescaledGate(GateX(), -0.5)
    @test_throws ArgumentError RescaledGate(GateX(), 1.1)

    for gate in [GateX(), GateRX(0.2), GateSWAP()]
        scale = rand()
        g = RescaledGate(gate, scale)

        @test getscale(g) == scale
        @test getoperation(g) == gate

        @test rescale(g, scale) isa RescaledGate
        @test getscale(rescale(g, scale)) == scale^2

        @test rescale(gate, scale) == g
    end
end

@testset "Propgate parameters" begin
    upars = rand(4)
    g = RescaledGate(GateU(upars...), 0.5)

    @test :m ∈ parnames(g)
    @test :θ ∈ parnames(g)
    @test :ϕ ∈ parnames(g)
    @test :λ ∈ parnames(g)
    @test :γ ∈ parnames(g)
    @test getparam(g, :θ) == upars[1]
    @test getparam(g, :ϕ) == upars[2]
    @test getparam(g, :λ) == upars[3]
    @test getparam(g, :γ) == upars[4]

    @test !issymbolic(g)
end

@testset "Symbolic Parameters" begin
    @variables λ
    g = RescaledGate(GateP(λ), λ^2 * π)
    @test issymbolic(g)
end

@testset "evaluate" begin
    @variables λ
    g = RescaledGate(GateP(λ), λ^2 * π)
    eg = evaluate(g, Dict(λ => 0.532))
    @test getparam(eg, :m) == 0.532^2 * π
    @test getparam(eg, :λ) == 0.532
end

@testset "matrix" begin
    @testset "Simple gate" begin
        g = RescaledGate(GateX(), 0.123)
        @test matrix(g) == 0.123 .* matrix(GateX())
    end

    @testset "Parametric gate" begin
        g = RescaledGate(GateRX(0.23), 0.123)
        @test matrix(g) == 0.123 .* matrix(GateRX(0.23))
    end
end

@testset "ProtoBuf" begin
    @testset "toproto / fromproto" begin
        using MimiqCircuitsBase: toproto, fromproto, circuit_pb

        @test toproto(RescaledGate(GateX(), 0.5)) isa circuit_pb.RescaledGate

        backforth = fromproto(toproto(RescaledGate(GateX(), 0.123)))
        @test backforth isa RescaledGate
        @test getscale(backforth) == 0.123
        @test getoperation(backforth) === GateX()

        backforth = fromproto(toproto(RescaledGate(GateRX(π * 0.324), 0.123)))
        @test backforth isa RescaledGate
        @test getscale(backforth) == 0.123
        @test getoperation(backforth) == GateRX(π * 0.324)
    end
end
