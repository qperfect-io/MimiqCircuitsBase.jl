#
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
#

using MimiqCircuitsBase
using Symbolics

@testset "GateDecl" begin
    @testset "Construction" begin
        # Manual construction
        @variables θ
        c = Circuit()
        push!(c, GateX(), 1)
        decl = GateDecl(:testgate, (Symbolics.value(θ),), c._instructions)
        
        @test decl.name == :testgate
        @test decl._arguments == (θ,)
        @test length(decl) == 1
        # Accessing private field directly for test purposes
        @test decl._instructions == c._instructions
    end

    @testset "Iteration and Indexing" begin
        @variables θ
        c = Circuit()
        push!(c, GateX(), 1)
        push!(c, GateRX(θ), 2)
        decl = GateDecl(:itergate, (Symbolics.value(θ),), c._instructions)

        # Test length
        @test length(decl) == 2
        @test !isempty(decl)

        # Test indexing
        @test decl[1] isa Instruction
        @test getoperation(decl[1]) == GateX()
        @test getoperation(decl[2]) == GateRX(θ)

        # Test iteration
        ops = [getoperation(inst) for inst in decl]
        @test ops == [GateX(), GateRX(θ)]

        # Test collect
        insts = collect(decl)
        @test insts isa Vector{<:Instruction}
        @test length(insts) == 2
    end

    @testset "Macro Usage" begin
        # Note: We don't need @variables phi outside, the macro handles arg names.
        @gatedecl mygate(ϕ) begin
            @on GateH() q=1
            @on GateRZ(ϕ) q=1
        end

        @test mygate isa GateDecl
        @test length(mygate) == 2
        @test mygate.name == :mygate
        
        # Test calling the gate
        gate_call = mygate(0.5)
        @test gate_call isa GateCall
        @test gate_call._decl == mygate
        @test gate_call._args == (0.5,)
    end
end
