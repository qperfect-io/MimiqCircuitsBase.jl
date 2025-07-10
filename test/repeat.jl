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

@testset "Repeat" begin
    @testset "Construction" begin
        r1 = Repeat(13, GateX())
        @test numqubits(r1) == 1
        @test numbits(r1) == 0
        @test numzvars(r1) == 0
        @test numrepeats(r1) == 13

        @test_throws ArgumentError Repeat(-1, GateX())

        r2 = Repeat(12, control(3, GateX()))
        @test numqubits(r2) == 4
        @test numbits(r2) == 0
        @test numzvars(r2) == 0
        @test numrepeats(r2) == 12

        r3 =  Repeat(11, Measure())
        @test numqubits(r3) == 1
        @test numbits(r3) == 1
        @test numzvars(r3) == 0
        @test numrepeats(r3) == 11
    end

    @testset "Simplified construction" begin
        r1 = repeat(3, GateX())
        @test numqubits(r1) == 1
        @test numrepeats(r1) == 3
        @test getoperation(r1) isa GateX
    end

    @testset "Interaction with Power and Inverse" begin
        # TODO: add this section
    end

    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            backforth = fromproto(toproto(Repeat(2, GateH())))
            @test backforth isa Repeat
            @test getoperation(backforth) isa GateH
            @test numrepeats(backforth) == 2

            backforth = fromproto(toproto(Repeat(4, control(3, GateH()))))
            @test backforth isa Repeat
            @test getoperation(backforth) isa Control
            @test getoperation(getoperation(backforth)) isa GateH
            @test numrepeats(backforth) == 4

            backforth = fromproto(toproto(Repeat(2, Measure())))
            @test backforth isa Repeat
            @test getoperation(backforth) isa Measure
            @test numrepeats(backforth) == 2
        end

        @testset "saveproto / loadproto" begin
            c = Circuit()
            push!(c, Repeat(3, GateX()), 1)
            push!(c, Repeat(3, GateX()), 4)
            push!(c, Repeat(3, GateCH()), 4, 5)
            push!(c, Repeat(3, GateRZZ(3.21)), 3, 4)

            b = Block(3,2,1)
            push!(b, GateH(), 1:3)
            push!(b, GateCX(), 1, 2:3)
            push!(b, Measure(), 1:2, 1:2)
            push!(b, IfStatement(GateX(), bs"11"), 3, 1, 2)
            push!(b, ExpectationValue(pauli"ZZ"), 1,3,1)
            push!(b, MeasureZZ(), 1,3,2)
            push!(b, Multiply(1, 0.5), 1)

            push!(c, Repeat(3, b), 1,2,3,1,2,1)

            testsaveloadproto(c)
        end
    end
end
