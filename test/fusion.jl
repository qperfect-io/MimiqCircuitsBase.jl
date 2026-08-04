using MimiqCircuitsBase
using LinearAlgebra
using Random
using Test

const _MCB = MimiqCircuitsBase

# Full unitary of a circuit's gate content, folded in circuit order. Non-gate
# ops (measure/reset/barrier) are skipped: fusion only regroups unitaries and
# never reorders non-commuting gates, so this product is invariant under `fuse`.
function _circuit_unitary(c, nq)
    U = Matrix{ComplexF64}(I, 2^nq, 2^nq)
    for inst in c
        getoperation(inst) isa AbstractGate || continue
        M = ComplexF64.(_MCB.unwrapvalue.(Matrix(matrix(inst, nq))))
        U = M * U
    end
    return U
end

@testset "fuse — unit cases" begin
    # H;H on q1 -> a single GateCustom{1} (two gates fuse; only lone gates stay)
    c = Circuit(); push!(c, GateH(), 1); push!(c, GateH(), 1)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{1}

    # CX;CX -> a single GateCustom{2} (~ identity)
    c = Circuit(); push!(c, GateCX(), 1, 2); push!(c, GateCX(), 1, 2)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{2}

    # H;CX -> one GateCustom{2} on support {1,2}
    c = Circuit(); push!(c, GateH(), 1); push!(c, GateCX(), 1, 2)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{2}
    @test getqubits(f[1]) == (1, 2)

    # Rx;Rz;CX with N=2 -> one GateCustom{2}
    c = Circuit(); push!(c, GateRX(0.3), 1); push!(c, GateRZ(0.5), 1); push!(c, GateCX(), 1, 2)
    f = fuse(c; max_support=2)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{2}

    # lone H between two barriers -> emitted as H, never GateCustom{1}
    c = Circuit(); push!(c, Barrier(1), 1); push!(c, GateH(), 1); push!(c, Barrier(1), 1)
    f = fuse(c)
    @test any(i -> getoperation(i) isa GateH, f)
    @test !any(i -> getoperation(i) isa GateCustom, f)

    # N=1 on a 2-qubit gate -> passes through unfused
    c = Circuit(); push!(c, GateCX(), 1, 2)
    f = fuse(c; max_support=1)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCX

    # boundary respect: H;Measure;H -> two separate H, no fusion across Measure
    c = Circuit(); push!(c, GateH(), 1); push!(c, Measure(), 1, 1); push!(c, GateH(), 1)
    f = fuse(c)
    @test count(i -> getoperation(i) isa GateH, f) == 2
    @test !any(i -> getoperation(i) isa GateCustom, f)
    @test count(i -> getoperation(i) isa Measure, f) == 1

    # a boundary that ends only one of a cluster's wires must still keep a later
    # gate on the other wire from fusing back across it
    c = Circuit()
    push!(c, GateH(), 2); push!(c, GateCX(), 1, 2); push!(c, GateCX(), 2, 1)
    push!(c, Measure(), 1, 1); push!(c, GateCX(), 1, 2); push!(c, GateH(), 2)
    @test isapprox(_circuit_unitary(c, 2), _circuit_unitary(fuse(c), 2); atol=1e-9)
end

@testset "fuse — non-contiguous support" begin
    # a 1-qubit gate sharing a cluster with a gate on higher/lower wires must be
    # embedded on its own wire, not the lowest one
    c = Circuit()
    push!(c, GateCX(), 1, 3); push!(c, GateH(), 3)
    f = fuse(c; max_support=2)
    @test isapprox(_circuit_unitary(c, 3), _circuit_unitary(f, 3); atol=1e-9)
end

@testset "fuse — invariants & random equivalence" begin
    @test length(fuse(Circuit())) == 0     # empty circuit

    gates1 = [() -> GateH(), () -> GateT(), () -> GateX(),
              () -> GateS(), () -> GateRX(0.37), () -> GateRZ(1.1)]
    gates2 = [GateCX(), GateCZ(), GateSWAP()]

    function randcirc(rng, nq, depth)
        c = Circuit()
        for _ in 1:depth
            r = rand(rng)
            if r < 0.5
                push!(c, rand(rng, gates1)(), rand(rng, 1:nq))
            elseif r < 0.85 && nq >= 2
                a = rand(rng, 1:nq); b = rand(rng, setdiff(1:nq, a))
                push!(c, rand(rng, gates2), a, b)
            elseif r < 0.93
                push!(c, Barrier(1), rand(rng, 1:nq))
            elseif r < 0.97
                q = rand(rng, 1:nq); push!(c, Measure(), q, q)
            else
                push!(c, Reset(), rand(rng, 1:nq))
            end
        end
        return c
    end

    rng = MersenneTwister(20260711)
    for N in 1:3, _ in 1:120
        nq = rand(rng, 1:6)
        c = randcirc(rng, nq, rand(rng, 2:18))
        f = fuse(c; max_support=N)
        @test length(f) <= length(c)
        @test isapprox(_circuit_unitary(c, nq), _circuit_unitary(f, nq); atol=1e-9)
    end
end
