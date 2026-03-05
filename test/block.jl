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

using MimiqCircuitsBase

@testset "Block" begin
    @testset "Construction" begin
        # Empty block construction
        b1 = Block()
        @test numqubits(b1) == 0
        @test numbits(b1) == 0
        @test numzvars(b1) == 0
        @test isempty(b1)
        @test length(b1) == 0

        # Block with specific dimensions
        b2 = Block(2, 1, 1)
        @test numqubits(b2) == 2
        @test numbits(b2) == 1
        @test numzvars(b2) == 1
        @test isempty(b2)

        # Block with named parameters
        b3 = Block(nq=3, nc=2, nz=1)
        @test numqubits(b3) == 3
        @test numbits(b3) == 2
        @test numzvars(b3) == 1

        # Create a block from a circuit
        c = Circuit()
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)
        b4 = Block(c)
        @test numqubits(b4) == 2
        @test numbits(b4) == 0
        @test numzvars(b4) == 0
        @test length(b4) == 2

        # Create a block directly from instructions
        insts = [Instruction(GateH(), (1,), (), ()), Instruction(GateCX(), (1, 2), (), ())]
        b5 = Block(insts)
        @test numqubits(b5) == 2
        @test numbits(b5) == 0
        @test numzvars(b5) == 0
        @test length(b5) == 2
    end

    @testset "Block Operations" begin
        # Test iterators and accessors
        b = Block(2, 1, 0)
        push!(b, GateH(), 1)
        push!(b, GateCX(), 1, 2)
        push!(b, Measure(), 1, 1)

        @test length(b) == 3
        @test b[1] == Instruction(GateH(), (1,), (), ())
        @test eltype(b) == Instruction

        # Test iteration
        ops = [getoperation(inst) for inst in b]
        @test ops == [GateH(), GateCX(), Measure()]

        # Test indexing
        b_slice = b[1:2]
        @test length(b_slice) == 2
        @test numqubits(b_slice) == 2
        @test getoperation(b_slice[1]) == GateH()

        # Test push! with bounds checking
        @test_throws ArgumentError push!(b, GateH(), 3)  # Out of qubit range
        @test_throws ArgumentError push!(b, Measure(), 1, 2)  # Out of bit range
    end

    @testset "Block in Circuit" begin
        # Create a block
        b = Block(2, 1, 0)
        push!(b, GateH(), 1)
        push!(b, GateCX(), 1, 2)

        # Add block to circuit
        c = Circuit()
        push!(c, b, 2, 3, 1)  # Target qubits 2,3 and bit 1
        c1 = decompose_step(c)

        # Check circuit after decomposition
        @test length(c1) == 2
        inst1, inst2 = c1[1], c1[2]
        @test getoperation(inst1) == GateH()
        @test getqubits(inst1) == (2,)  # Mapped from 1 to 2
        @test getoperation(inst2) == GateCX()
        @test getqubits(inst2) == (2, 3)  # Mapped from [1,2] to [2,3]

        # Test complex nesting with Decompose
        b_inner = Block(1, 0, 0)
        push!(b_inner, GateX(), 1)

        b_outer = Block(2, 0, 0)
        push!(b_outer, GateH(), 1)
        push!(b_outer, b_inner, 2)

        c2 = decompose_step(b_outer)
        @test length(c2) == 2
        @test getoperation(c2[1]) == GateH()
        @test getoperation(c2[2]) == b_inner
    end

    @testset "Protobuf Serialization" begin
        # Create a block with various operations
        b = Block(2, 1, 0)
        push!(b, GateH(), 1)
        push!(b, GateCX(), 1, 2)
        push!(b, Measure(), 2, 1)

        # Create a circuit with the block
        c = Circuit()
        push!(c, b, 3, 4, 2)

        # Serialize to protobuf
        io = IOBuffer()
        saveproto(io, c)
        seekstart(io)

        # Deserialize from protobuf
        restored_circuit = loadproto(io, Circuit)

        # Check if the restored circuit has the same instructions
        @test length(restored_circuit) == 1

        # Check individual instructions
        @test getoperation(restored_circuit[1]) isa Block
        @test getqubits(restored_circuit[1]) == (3, 4)
        @test getbits(restored_circuit[1]) == (2,)

        # Nested blocks
        inner_block = Block(1, 0, 0)
        push!(inner_block, GateX(), 1)

        outer_block = Block(2, 0, 0)
        push!(outer_block, GateH(), 1)
        push!(outer_block, inner_block, 2)

        circuit_nested = Circuit()
        push!(circuit_nested, outer_block, 1, 2)

        io_nested = IOBuffer()
        saveproto(io_nested, circuit_nested)
        seekstart(io_nested)

        restored_nested = loadproto(io_nested, Circuit)

        @test length(restored_nested) == 1

        restored_block = getoperation(restored_nested[1])
        @test getoperation(restored_nested[1]) isa Block
        @test getoperation(restored_block[1]) isa GateH
        @test getoperation(restored_block[2]) isa Block
    end
end
