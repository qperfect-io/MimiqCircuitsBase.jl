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

@testset "Instruction" begin
    @test_throws ArgumentError Instruction(GateX(), 1, 2)
    @test_throws ArgumentError Instruction(GateCX(), 1)
    @test_throws ArgumentError Instruction(GateCX(), 1, 1)
    @test_throws ArgumentError Instruction(GateX(), -1)
    @test_throws ArgumentError Instruction(GateCX(), 1, -1)
    @test_throws ArgumentError Instruction(GateCX(), -1, 1)
end

@testset "Bit aliasing trait" begin
    # Default: bit and zvar uniqueness still enforced
    @test allow_bit_aliasing(typeof(ParityCheck())) === false
    @test allow_zvar_aliasing(typeof(GateX())) === false
    @test_throws ArgumentError push!(Circuit(), ParityCheck(), 1, 1, 2)
    @test_throws ArgumentError Instruction(ParityCheck(), (), (1, 1, 2), ())

    # Qubit uniqueness is never relaxed (no-cloning).
    @test_throws ArgumentError Instruction(GateCX(), 1, 1)

    # And/Or/Xor opt in: aliased bits (output == one of the inputs) accepted.
    @test allow_bit_aliasing(typeof(And(3))) === true
    a = Instruction(And(3), (), (1, 1, 2), ())
    @test getbits(a) == (1, 1, 2)
    @test push!(Circuit(), And(3), 1, 1, 2) isa Circuit
    @test push!(Circuit(), Or(3), 1, 1, 2) isa Circuit
    @test push!(Circuit(), Xor(3), 1, 1, 2) isa Circuit

    # IfStatement opts in: body bits may overlap condition bits.
    @test allow_bit_aliasing(typeof(IfStatement(Not(), BitString("1")))) === true
    ifs = IfStatement(Not(), BitString("1"))
    @test push!(Circuit(), ifs, 1, 1) isa Circuit

    # Add/Multiply/Pow opt in for zvars.
    @test allow_zvar_aliasing(typeof(Add(2))) === true
    @test allow_zvar_aliasing(typeof(Multiply(2))) === true
    @test allow_zvar_aliasing(typeof(Pow(2.0))) === true
    @test push!(Circuit(), Add(2), 1, 1) isa Circuit
    @test push!(Circuit(), Multiply(2), 1, 1) isa Circuit

    # Wrappers do NOT opt in — their outer targets must remain unique.
    @test allow_bit_aliasing(Block) === false
    @test allow_bit_aliasing(typeof(Repeat(2, GateX()))) === false
end

