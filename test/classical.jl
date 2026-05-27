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
using Test

const CLASSICALOPS = [Not(), SetBit0(), SetBit1(), And(), And(5), And(8), Or(), Or(6), Or(10), Xor(), Xor(4), Xor(7), ParityCheck(), ParityCheck(5)]

@testset "$(string(typeof(op)))" for op in CLASSICALOPS
    @testset "ProtoBuf" begin
        @testset "toproto / fromproto" begin
            using MimiqCircuitsBase: toproto, fromproto, circuit_pb

            backforth = fromproto(toproto(op))
            @test typeof(backforth) == typeof(op)
        end

        @testset "saveproto / loadproto" begin
            c = push!(Circuit(), op, 1:numbits(op)...)
            testsaveloadproto(c)
        end
    end
end

@testset "Aliased classical/complex ops construction" begin
    # Construction-level tests only — runtime apply! tests live in AbstractQCSs/
    # StateVecSim test suites where AbstractQCSs is available.

    # And/Or/Xor accept aliased bits.
    @test Instruction(And(3), (), (1, 1, 2), ()) isa Instruction
    @test Instruction(Or(3), (), (1, 1, 2), ()) isa Instruction
    @test Instruction(Xor(3), (), (1, 1, 1), ()) isa Instruction

    # Push to circuit also works.
    @test push!(Circuit(), And(3), 1, 1, 2) isa Circuit
    @test push!(Circuit(), Or(3), 1, 2, 2) isa Circuit
    @test push!(Circuit(), Xor(3), 1, 1, 1) isa Circuit

    # Add/Multiply accept aliased zvars.
    @test Instruction(Add(2), (), (), (1, 1)) isa Instruction
    @test Instruction(Multiply(2), (), (), (1, 1)) isa Instruction
    @test push!(Circuit(), Add(2), 1, 1) isa Circuit
    @test push!(Circuit(), Multiply(2), 1, 1) isa Circuit

    # Protobuf round-trips a circuit with aliased targets.
    let c = push!(Circuit(), And(3), 1, 1, 2)
        testsaveloadproto(c)
    end
    let c = push!(Circuit(), Add(2), 1, 1)
        testsaveloadproto(c)
    end
end

