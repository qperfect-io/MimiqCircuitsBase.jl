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

@testset "remove_swaps" begin

    strip_ids(circ) = [inst for inst in circ if !(getoperation(inst) isa GateID)]

    @testset "non-recursive" begin
        @testset "single SWAP removal" begin
            c = Circuit()
            push!(c, GateH(), 1)
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateCX(), 2, 3)
            new_c, perm = remove_swaps(c)

            insts = strip_ids(new_c)
            @test length(insts) == 2
            @test perm == [2, 1, 3]
            @test !any(inst -> getoperation(inst) isa GateSWAP, new_c)
            @test getoperation(insts[1]) isa GateH
            @test collect(getqubits(insts[1])) == [1]
            @test getoperation(insts[2]) isa GateCX
            @test collect(getqubits(insts[2])) == [1, 3]
        end

        @testset "multiple SWAPs (chain)" begin
            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateSWAP(), 2, 3)
            push!(c, GateCX(), 1, 3)
            new_c, perm = remove_swaps(c)

            @test perm == [2, 3, 1]
            @test !any(inst -> getoperation(inst) isa GateSWAP, new_c)
            insts = strip_ids(new_c)
            @test length(insts) == 1
            @test collect(getqubits(insts[1])) == [2, 1]
        end

        @testset "cancelling SWAPs" begin
            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateH(), 1)
            new_c, perm = remove_swaps(c)

            @test perm == [1, 2]
            insts = strip_ids(new_c)
            @test length(insts) == 1
            @test getoperation(insts[1]) isa GateH
            @test collect(getqubits(insts[1])) == [1]
        end

        @testset "no SWAPs (identity)" begin
            c = Circuit()
            push!(c, GateH(), 1)
            push!(c, GateCX(), 1, 2)
            new_c, perm = remove_swaps(c)

            @test perm == [1, 2]
            insts = collect(new_c)
            @test length(insts) == 2
        end

        @testset "empty circuit" begin
            c = Circuit()
            new_c, perm = remove_swaps(c)
            @test isempty(collect(new_c))
            @test perm == Int[]
        end

        @testset "SWAP-only circuit" begin
            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateSWAP(), 2, 3)
            new_c, perm = remove_swaps(c)

            @test numqubits(new_c) == 3
            @test perm == [2, 3, 1]
            @test !any(inst -> getoperation(inst) isa GateSWAP, new_c)
        end

        @testset "SWAP at end" begin
            c = Circuit()
            push!(c, GateH(), 1)
            push!(c, GateSWAP(), 1, 2)
            new_c, perm = remove_swaps(c)

            @test perm == [2, 1]
            @test numqubits(new_c) == 2
            insts = strip_ids(new_c)
            @test length(insts) == 1
            @test getoperation(insts[1]) isa GateH
            @test collect(getqubits(insts[1])) == [1]
        end

        @testset "preserves bits and zvars" begin
            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, Measure(), 2, 1)
            new_c, perm = remove_swaps(c)

            insts = strip_ids(new_c)
            @test length(insts) == 1
            @test collect(getqubits(insts[1])) == [1]
            @test collect(getbits(insts[1])) == [1]
        end

        @testset "preserves circuit qubit count" begin
            c = Circuit()
            push!(c, GateX(), 1)
            push!(c, GateSWAP(), 1, 2)

            cnew, perm = remove_swaps(c)

            @test numqubits(cnew) == 2
            @test perm == [2, 1]
        end

        @testset "does not recurse into GateCall without recursive flag" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateH(), 1)
            decl = GateDecl(:Inner, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2)
            new_c, perm = remove_swaps(c)

            @test perm == [1, 2]
            insts = collect(new_c)
            op = getoperation(insts[1])
            @test op isa GateCall
            # Inner SWAPs should still be there
            inner_insts = op._decl._instructions
            @test any(inst -> getoperation(inst) isa GateSWAP, inner_insts)
        end
    end

    @testset "recursive GateCall" begin
        @testset "simple GateCall with SWAP" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateCX(), 1, 2)
            decl = GateDecl(:Inner, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2)
            push!(c, GateH(), 1)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [2, 1]
            # GateCall's internal SWAPs should be removed
            insts = collect(new_c)
            gcall = getoperation(insts[1])
            @test gcall isa GateCall
            @test !any(inst -> getoperation(inst) isa GateSWAP, gcall._decl._instructions)
            # H should be remapped due to block permutation
            @test collect(getqubits(insts[2])) == [2]
        end

        @testset "deeply nested GateDecl" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateCX(), 2, 1)
            Inner = GateDecl(:Inner, (), inner)

            mid = Circuit()
            push!(mid, GateSWAP(), 1, 2)
            push!(mid, GateCall(Inner), 1, 2)
            Mid = GateDecl(:Mid, (), mid)

            outer = Circuit()
            push!(outer, GateSWAP(), 1, 2)
            push!(outer, GateCall(Mid), 1, 2)
            Outer = GateDecl(:Outer, (), outer)

            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateCall(Outer), 1, 2)

            new_c, _ = remove_swaps(c; recursive=true)

            # No SWAPs at any level
            @test !any(inst -> getoperation(inst) isa GateSWAP, new_c)

            Outer2 = getoperation(collect(new_c)[1])._decl
            @test !any(inst -> getoperation(inst) isa GateSWAP, Outer2._instructions)

            Mid2 = getoperation(Outer2._instructions[1])._decl
            @test !any(inst -> getoperation(inst) isa GateSWAP, Mid2._instructions)

            Inner2 = getoperation(Mid2._instructions[1])._decl
            @test !any(inst -> getoperation(inst) isa GateSWAP, Inner2._instructions)
        end

        @testset "GateDecl arity preservation" begin
            inner = Circuit()
            push!(inner, GateH(), 1)
            push!(inner, GateSWAP(), 2, 3)
            decl = GateDecl(:Test, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2, 3)
            new_c, perm = remove_swaps(c; recursive=true)

            gcall = getoperation(collect(new_c)[1])
            @test numqubits(gcall) == 3
        end

        @testset "shared GateDecl caching" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateH(), 1)
            decl = GateDecl(:Shared, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2)
            push!(c, GateCall(decl), 3, 4)
            new_c, perm = remove_swaps(c; recursive=true)

            insts = collect(new_c)
            decl1 = getoperation(insts[1])._decl
            decl2 = getoperation(insts[2])._decl
            @test decl1 === decl2
        end
    end

    @testset "recursive Block" begin
        @testset "simple Block with SWAP" begin
            block = Block([
                Instruction(GateSWAP(), (1, 2), (), ()),
                Instruction(GateH(), (1,), (), ()),
            ])
            c = Circuit()
            push!(c, block, 3, 4)
            push!(c, GateCX(), 3, 4)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2, 4, 3]
            @test !any(inst -> getoperation(inst) isa GateSWAP, new_c)
        end

        @testset "Block dimension preservation" begin
            block = Block(3, 0, 0, [
                Instruction(GateSWAP(), (1, 2), (), ()),
                Instruction(GateH(), (1,), (), ()),
            ])
            c = Circuit()
            push!(c, block, 1, 2, 3)
            push!(c, GateCX(), 1, 3)
            new_c, perm = remove_swaps(c; recursive=true)

            insts = collect(new_c)
            new_block = getoperation(insts[1])
            @test numqubits(new_block) == 3
            @test perm == [2, 1, 3]
        end

        @testset "Block with bits and zvars preserved" begin
            block = Block(2, 1, 0, [
                Instruction(GateSWAP(), (1, 2), (), ()),
                Instruction(Measure(), (1,), (1,), ()),
            ])
            c = Circuit()
            push!(c, block, 1, 2, 1)
            new_c, perm = remove_swaps(c; recursive=true)

            insts = collect(new_c)
            new_block = getoperation(insts[1])
            @test numbits(new_block) == 1
        end
    end

    @testset "Inverse/Control/IfStatement handling" begin
        inner = Circuit()
        push!(inner, GateSWAP(), 1, 2)
        push!(inner, GateCX(), 1, 2)
        decl = GateDecl(:Inner, (), inner)

        @testset "Inverse(GateCall) recursed preserving wrapper" begin
            c = Circuit()
            push!(c, Inverse(GateCall(decl)), 1, 2)
            push!(c, GateH(), 1)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [2, 1]
            insts = collect(new_c)
            @test getoperation(insts[1]) isa Inverse
            # Navigate through wrapper to check inner SWAPs removed
            inner_decl = getoperation(getoperation(insts[1]))._decl
            @test !any(inst -> getoperation(inst) isa GateSWAP, inner_decl._instructions)
            # H should be remapped due to the permutation
            @test collect(getqubits(insts[2])) == [2]
        end

        @testset "Control(GateCall) not recursed into" begin
            c = Circuit()
            push!(c, control(1, GateCall(decl)), 1, 2, 3)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2, 3]
            insts = collect(new_c)
            @test getoperation(insts[1]) isa Control
        end

        @testset "IfStatement(Block) not recursed into" begin
            block = Block([
                Instruction(GateSWAP(), (1, 2), (), ()),
                Instruction(GateH(), (1,), (), ()),
            ])
            ifs = IfStatement(block, BitString(1, [true]))
            c = Circuit()
            push!(c, ifs, 1, 2, 1)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2]
            insts = collect(new_c)
            @test getoperation(insts[1]) isa IfStatement
        end

        @testset "outer SWAP + Inverse SWAP cancel" begin
            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, Inverse(GateCall(decl)), 1, 2)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2]
        end

        @testset "forward + inverse GateCall compose to identity perm" begin
            swap_insts = [
                Instruction(GateSWAP(), (1, 2), (), ()),
                Instruction(GateSWAP(), (2, 3), (), ())
            ]
            swap_decl = GateDecl(:Grecursive, (), swap_insts)
            gcall = GateCall(swap_decl)

            c = Circuit()
            push!(c, gcall, 1, 2, 3)
            push!(c, inverse(gcall), 1, 2, 3)

            cnew, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2, 3]
            @test getqubits(cnew[1]) == (1, 2, 3)
            @test getoperation(cnew[2]) isa Inverse
            @test getqubits(cnew[2]) == (2, 3, 1)
        end
    end

    @testset "permutation composition" begin
        @testset "SWAP before recursive GateCall" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateH(), 1)
            decl = GateDecl(:Inner, (), inner)

            c = Circuit()
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateCall(decl), 1, 2)
            push!(c, GateH(), 1)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2]
        end

        @testset "SWAP after recursive GateCall" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateH(), 1)
            decl = GateDecl(:Inner, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2)
            push!(c, GateSWAP(), 1, 2)
            push!(c, GateH(), 1)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [1, 2]
        end

        @testset "mixed GateCalls and SWAPs" begin
            inner = Circuit()
            push!(inner, GateSWAP(), 1, 2)
            push!(inner, GateH(), 1)
            decl = GateDecl(:Inner, (), inner)

            c = Circuit()
            push!(c, GateCall(decl), 1, 2)
            push!(c, GateCall(decl), 2, 3)
            new_c, perm = remove_swaps(c; recursive=true)

            @test perm == [2, 3, 1]
        end
    end

    @testset "commutes with flattening" begin
        insts = [
            Instruction(GateSWAP(), (1, 2), (), ()),
            Instruction(GateCX(), (1, 3), (), ()),
            Instruction(GateSWAP(), (2, 3), (), ())
        ]
        decl = GateDecl(:GinverseMixed, (), insts)
        gcall = GateCall(decl)

        c = Circuit()
        push!(c, inverse(gcall), 1, 2, 3)

        cflat = decompose(c; basis=FlattenContainers())
        cpath_a, perm_a = remove_swaps(cflat)

        crec, perm_b = remove_swaps(c; recursive=true)
        cpath_b = decompose(crec; basis=FlattenContainers())

        a = strip_ids(cpath_a)
        b = strip_ids(cpath_b)

        @test perm_a == perm_b
        @test length(a) == length(b)
        @test map(getoperation, a) == map(getoperation, b)
        @test map(getqubits, a) == map(getqubits, b)
    end
end
