#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
#

using MimiqCircuitsBase
using Symbolics

@testset "BlockDecl" begin
    @variables θ φ

    @testset "Construction" begin
        c = Circuit()
        push!(c, GateRX(θ), 1)
        push!(c, Measure(), 2, 1)

        decl = BlockDecl(:syn, (θ,), c)
        @test decl.name == :syn
        @test isequal(decl._arguments, (Symbolics.value(θ),))
        @test (numqubits(decl), numbits(decl), numzvars(decl)) == (2, 1, 0)
        @test length(decl) == 2
        @test decl == BlockDecl(:syn, (θ,), c._instructions)

        # the body is copied
        push!(c, GateH(), 1)
        @test length(decl) == 2

        # a Block keeps its declared sizes
        b = Block(3, 2, 1)
        push!(b, GateH(), 1)
        decl = BlockDecl(:wide, (), b)
        @test (numqubits(decl), numbits(decl), numzvars(decl)) == (3, 2, 1)

        # declarations with no parameters and no instructions are allowed
        @test length(BlockDecl(:empty, (), Instruction[])) == 0
    end

    @testset "Validation" begin
        c = push!(Circuit(), GateRX(θ), 1)
        @test_throws ArgumentError BlockDecl(:bad, (θ + 1,), c)
        @test_throws ArgumentError BlockDecl(:bad, (θ, θ), c)
        # θ is used in the body but is not an argument
        @test_throws ArgumentError BlockDecl(:bad, (), c)
        @test_throws ArgumentError BlockDecl(:bad, (φ,), c)
        # the body does not fit the declared sizes
        @test_throws ArgumentError BlockDecl{1,0,0}(:bad, (), [Instruction(GateCX(), 1, 2)])
    end

    @testset "Macro" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
            @on GateCX() q=(1, 2)
            @on Measure() q=2 c=1
        end
        @test syn isa BlockDecl{2,1,0,1}
        @test syn.name == :syn

        @blockdecl prep() begin
            @on GateH() q=1
        end
        @test prep isa BlockDecl{1,0,0,0}
        @test prep() isa BlockCall{1,0,0,0}
    end

    @testset "Call" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
            @on Measure() q=2 c=1
        end

        call = syn(0.1)
        @test call isa BlockCall{2,1,0,1}
        @test call isa Operation{2,1,0}
        @test call._decl === syn
        @test numparams(call) == 1
        @test opname(call) == "BlockCall"
        @test !isunitary(call)
        @test call == syn(0.1)
        @test call != syn(0.2)
        @test_throws ArgumentError syn()
        @test_throws ArgumentError syn(0.1, 0.2)

        @blockdecl rot(α) begin
            @on GateRX(α) q=1
        end
        @test isunitary(rot(0.1))
    end

    @testset "Circuit and decomposition" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
            @on GateCX() q=(1, 2)
            @on Measure() q=2 c=1
        end

        c = Circuit()
        push!(c, syn(0.1), 1, 2, 1)
        push!(c, syn(0.2), 4, 3, 2)
        @test numqubits(c) == 4
        @test numbits(c) == 2

        expected = Circuit()
        push!(expected, GateRX(0.1), 1)
        push!(expected, GateCX(), 1, 2)
        push!(expected, Measure(), 2, 1)
        push!(expected, GateRX(0.2), 4)
        push!(expected, GateCX(), 4, 3)
        push!(expected, Measure(), 3, 2)

        @test decompose_step(c) == expected
        @test decompose(c; basis=FlattenedBasis()) == expected
        @test decompose_step(c; rule=FlattenContainers()) == expected

        # z-variables are remapped too
        @blockdecl ev() begin
            @on ExpectationValue(GateZ()) q=1 z=1
        end
        c = push!(Circuit(), ev(), 2, 3)
        @test getztargets(decompose_step(c)[1]) == (3,)

        # calls nested in a declaration
        @blockdecl outer(β) begin
            @on syn(2β) q=(1, 2) c=1
        end
        c = push!(Circuit(), outer(0.1), 1, 2, 1)
        @test decompose(c; basis=FlattenedBasis()) == decompose(push!(Circuit(), syn(0.2), 1, 2, 1); basis=FlattenedBasis())
    end

    @testset "Symbolics" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
        end

        call = syn(2θ)
        @test issymbolic(call)
        @test isequal(listvars(call), [θ])
        @test !issymbolic(syn(0.1))
        @test isempty(listvars(syn(0.1)))

        c = push!(Circuit(), call, 1)
        @test isequal(listvars(c), [θ])

        evaluated = evaluate(call, Dict(θ => 0.5))
        @test evaluated == syn(1.0)
        @test evaluated._decl === syn

        ec = evaluate(c, Dict(θ => 0.5))
        @test getoperation(ec[1])._decl === syn
        @test decompose_step(ec) == push!(Circuit(), GateRX(1.0), 1)
    end

    @testset "Block equality" begin
        b1 = push!(Block(1, 0, 0), GateH(), 1)
        b2 = push!(Block(1, 0, 0), GateX(), 1)
        @test b1 != b2
        @test b1 == push!(Block(1, 0, 0), GateH(), 1)
    end

    @testset "GateCall symbolics" begin
        @gatedecl rot(α) begin
            @on GateRX(α) q=1
        end
        @test issymbolic(rot(θ))
        @test !issymbolic(rot(0.1))
        @test issetequal(listvars(rot(θ + φ)), [θ, φ])
    end

    @testset "Protobuf" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
            @on Measure() q=2 c=1
        end

        c = Circuit()
        push!(c, syn(0.1), 1, 2, 1)
        push!(c, syn(θ), 3, 4, 2)
        push!(c, GateH(), 1)

        pb = MimiqCircuitsBase.toproto(c)
        # both calls refer to a single stored declaration
        @test length(pb.decls) == 1

        io = IOBuffer()
        saveproto(io, c)
        seekstart(io)
        restored = loadproto(io, Circuit)

        @test restored == c
        @test getoperation(restored[1])._decl === getoperation(restored[2])._decl

        # macro-made gate declarations load back equal as well
        @gatedecl rot(γ) begin
            @on GateRX(γ) q=1
        end
        g = push!(Circuit(), rot(0.2), 1)
        @test MimiqCircuitsBase.fromproto(MimiqCircuitsBase.toproto(g)) == g

        # outside a circuit the declaration is written inline
        call = syn(0.3)
        @test MimiqCircuitsBase.fromproto(MimiqCircuitsBase.toproto(call)) == call

        # nested declarations are stored before the ones that use them
        @blockdecl outer(β) begin
            @on syn(β) q=(1, 2) c=1
            @on syn(2β) q=(2, 1) c=1
        end
        c = push!(Circuit(), outer(0.4), 1, 2, 1)
        pb = MimiqCircuitsBase.toproto(c)
        @test length(pb.decls) == 2
        restored = MimiqCircuitsBase.fromproto(pb)
        @test restored == c
        inner = getoperation(restored[1])._decl
        @test getoperation(inner[1])._decl === getoperation(inner[2])._decl
    end

    @testset "Noise model" begin
        model = NoiseModel([
            OperationInstanceNoise(GateH(), AmplitudeDamping(0.01))
        ])

        @blockdecl prep() begin
            @on GateH() q=1
            @on Measure() q=1 c=1
        end
        c = push!(Circuit(), prep(), 1, 1)

        noisy = apply_noise_model(c, model)
        @test length(noisy) == 1
        inner = getoperation(noisy[1])
        @test inner isa Block
        @test getoperation.(collect(inner)) == [GateH(), AmplitudeDamping(0.01), Measure()]
    end

    @testset "Display" begin
        @blockdecl syn(α) begin
            @on GateRX(α) q=1
        end
        @test sprint(show, MIME"text/plain"(), syn(0.5)) == "syn(0.5)"
        @test startswith(sprint(show, MIME"text/plain"(), syn), "block syn(α) =")

        @blockdecl prep() begin
            @on GateH() q=1
        end
        @test sprint(show, MIME"text/plain"(), prep()) == "prep"
    end
end
