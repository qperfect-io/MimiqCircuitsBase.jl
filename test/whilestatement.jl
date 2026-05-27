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

using Test

@testset "WhileStatement Constructor" begin
    gate = GateX()
    bs = BitString("1")
    ws = WhileStatement(gate, bs)

    @test opname(ws) == "WHILE"
    @test numqubits(ws) == 1
    @test numbits(ws) == numbits(gate) + length(bs)
    @test numzvars(ws) == 0
    @test getoperation(ws) === gate
    @test getbitstring(ws) == bs
    @test isunitary(ws) === true

    @test allow_bit_aliasing(typeof(ws)) === true
    @test allow_zvar_aliasing(typeof(ws)) === true
    @test isunitary(WhileStatement(Not(), BitString("1"))) === false
end

@testset "WhileStatement equality and inverse" begin
    a = WhileStatement(GateX(), BitString("1"))
    b = WhileStatement(GateX(), BitString("1"))
    c = WhileStatement(GateX(), BitString("0"))
    d = WhileStatement(GateY(), BitString("1"))

    @test a == b
    @test a != c
    @test a != d

    @test_throws ErrorException inverse(a)
end

@testset "WhileStatement push! with aliased bits" begin
    # Body is `Not()` which acts on the same bit used as condition.
    body = Not()
    ws = WhileStatement(body, BitString("1"))

    # Body has 1 bit, condition has 1 bit, M = 2.
    @test numbits(ws) == 2

    # Aliased push: body bit 1 == condition bit 1.
    c = push!(Circuit(), ws, 1, 1)
    @test c isa Circuit
    @test length(c._instructions) == 1
end

@testset "WhileStatement protobuf round-trip" begin
    using MimiqCircuitsBase: toproto, fromproto

    ws = WhileStatement(Not(), BitString("1"))
    backforth = fromproto(toproto(ws))
    @test backforth == ws

    # Round-trip in a circuit
    c = push!(Circuit(), ws, 1, 1)
    testsaveloadproto(c)
end

@testset "WhileStatement decomposition preserves loop" begin
    # decomposition of a WhileStatement should leave the loop boundary intact:
    # the body may be rewritten but the result is still one WhileStatement
    # instruction (or one wrapping a Block), not unrolled.
    ws = WhileStatement(Not(), BitString("1"))
    c = push!(Circuit(), ws, 1, 1)
    d = decompose(c)

    @test length(d._instructions) == 1
    @test getoperation(d._instructions[1]) isa WhileStatement
end
