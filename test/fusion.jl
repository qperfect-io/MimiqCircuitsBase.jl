using MimiqCircuitsBase
using LinearAlgebra
using Random
using Test
using Symbolics

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
    for N in 1:5, _ in 1:120
        nq = rand(rng, 1:6)
        c = randcirc(rng, nq, rand(rng, 2:18))
        f = fuse(c; max_support=N)
        @test length(f) <= length(c)
        @test isapprox(_circuit_unitary(c, nq), _circuit_unitary(f, nq); atol=1e-9)
    end
end

@testset "fuse — diagonal clusters" begin
    # an all-diagonal run collapses into a GateCustomDiagonal, not a GateCustom
    c = Circuit(); push!(c, GateP(0.1), 1); push!(c, GateCZ(), 1, 2); push!(c, GateRZ(0.3), 2)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustomDiagonal{2}
    @test isapprox(_circuit_unitary(c, 2), _circuit_unitary(f, 2); atol=1e-12)

    # one dense gate in the run is enough to make the block dense
    c = Circuit(); push!(c, GateP(0.1), 1); push!(c, GateH(), 1); push!(c, GateCZ(), 1, 2)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{2}
    @test isapprox(_circuit_unitary(c, 2), _circuit_unitary(f, 2); atol=1e-12)

    # a diagonal chain wider than max_support fuses only under the diagonal budget
    c = Circuit()
    for q in 1:4
        push!(c, GateP(0.1q), q)
    end
    push!(c, GateCZ(), 1, 2); push!(c, GateCZ(), 2, 3); push!(c, GateCZ(), 3, 4)
    @test length(fuse(c; max_support=2)) > 1
    f = fuse(c; max_support=2, max_diagonal_support=4)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustomDiagonal{4}
    @test getqubits(f[1]) == (1, 2, 3, 4)
    @test isapprox(_circuit_unitary(c, 4), _circuit_unitary(f, 4); atol=1e-12)

    # a GateCustomDiagonal member is folded without ever being densified, and
    # unsorted targets pick their entries in target order
    g = GateCustomDiagonal([1, im, -1, -im])
    c = Circuit(); push!(c, g, 2, 1); push!(c, GateCustomDiagonal([1, cis(1.1)]), 1)
    f = fuse(c)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustomDiagonal{2}
    @test isapprox(_circuit_unitary(c, 2), _circuit_unitary(f, 2); atol=1e-12)

    # max_diagonal_support below max_support only means diagonal runs get no
    # extra room; they still fuse densely up to max_support
    c = Circuit(); push!(c, GateP(0.1), 1); push!(c, GateCZ(), 1, 2)
    f = fuse(c; max_support=2, max_diagonal_support=1)
    @test length(f) == 1
    @test getoperation(f[1]) isa GateCustom{2}
    @test isapprox(_circuit_unitary(c, 2), _circuit_unitary(f, 2); atol=1e-12)

    # random mixed circuits: a wider diagonal budget never breaks the unitary
    rng = MersenneTwister(20260818)
    gatesd = [() -> GateP(rand(rng)), () -> GateZ(), () -> GateT(), () -> GateRZ(rand(rng))]
    for _ in 1:120
        nq = rand(rng, 2:5)
        c = Circuit()
        for _ in 1:rand(rng, 2:20)
            r = rand(rng)
            a = rand(rng, 1:nq); b = rand(rng, setdiff(1:nq, a))
            if r < 0.4
                push!(c, rand(rng, gatesd)(), a)
            elseif r < 0.7
                push!(c, GateCZ(), a, b)
            elseif r < 0.85
                push!(c, GateH(), a)
            else
                push!(c, GateCX(), a, b)
            end
        end
        for mds in 1:5
            f = fuse(c; max_support=2, max_diagonal_support=mds)
            @test length(f) <= length(c)
            @test isapprox(_circuit_unitary(c, nq), _circuit_unitary(f, nq); atol=1e-9)
        end
    end
end

@testset "fuse — clusters merge past two qubits" begin
    # Brick-wall entangling layers: after the first layer every wire is owned,
    # so each later gate bridges two clusters. Fusion used to refuse every such
    # bridge, which pinned the output at the max_support = 2 result no matter
    # how wide the budget was.
    function brickwall(nq, layers)
        c = Circuit()
        for l in 1:layers, q in (isodd(l) ? (1:2:nq-1) : (2:2:nq-1))
            push!(c, GateH(), q)
            push!(c, GateCX(), q, q + 1)
        end
        return c
    end

    nq = 5
    c = brickwall(nq, 4)
    counts = [length(fuse(c; max_support=k)) for k in 2:nq]
    @test issorted(counts; rev=true)          # wider budget never fuses worse
    @test counts[end] < counts[1]             # ... and here it fuses strictly better

    # A cluster wider than two qubits has to actually be emitted.
    @test any(numqubits(getoperation(inst)) > 2 for inst in fuse(c; max_support=4))

    ref = _circuit_unitary(c, nq)
    for k in (2, nq)
        @test isapprox(ref, _circuit_unitary(fuse(c; max_support=k), nq); atol=1e-9)
    end
end

@testset "fuse — merging never closes a cycle" begin
    # g1 and g3 both look mergeable at g4, but g2 sits between them: fusing the
    # two into one block would need g2 to run both after and before it.
    c = Circuit()
    push!(c, GateCX(), 1, 2)
    push!(c, GateCX(), 2, 3)
    push!(c, GateCX(), 3, 4)
    push!(c, GateCX(), 1, 4)
    ref = _circuit_unitary(c, 4)
    for k in 2:4
        @test isapprox(ref, _circuit_unitary(fuse(c; max_support=k), 4); atol=1e-9)
    end
end

@testset "matrix(::Vector{Instruction}) keeps a stable element type" begin
    # The contract is `Complex{Num}` regardless of content: deriving the element
    # type from whether any gate happens to be symbolic would make the return
    # type depend on the argument's *value*, and every caller type-unstable.
    @variables θ
    @test eltype(matrix([Instruction(GateH(), 1), Instruction(GateCX(), 1, 2)])) == Complex{Num}
    @test eltype(matrix([Instruction(GateH(), 1), Instruction(GateRZ(θ), 1)])) == Complex{Num}
    @test eltype(matrix([Instruction(GateX(), 1)])) == Complex{Num}
    @test eltype(matrix(Circuit())) == Complex{Num}

    # Gate matrices span Int64/Float64/ComplexF64/Num/Complex{Num}, and Symbolics
    # leaves promote_type(ComplexF64, Num) ambiguous. `GateRY` with a symbolic
    # angle is the only gate yielding a plain `Num` matrix, so mixing it with a
    # complex numeric gate is what a naive promotion trips over.
    @test eltype(matrix([Instruction(GateRY(θ), 1)])) == Complex{Num}
    for other in (Instruction(GateRZ(0.5), 1), Instruction(GateP(0.3), 1), Instruction(GateH(), 1))
        @test eltype(matrix([other, Instruction(GateRY(θ), 1)])) == Complex{Num}
    end

    # ... while the numeric fold `fuse` uses stays on BLAS types
    insts = [Instruction(GateH(), 1), Instruction(GateCX(), 1, 2), Instruction(GateRZ(0.5), 2)]
    @test eltype(_MCB._foldmatrices(map(i -> matrix(i, 2), insts), 2, ComplexF64)) == ComplexF64
end

@testset "_index_permutation matches the obvious form" begin
    # All permutations of 1:n, without pulling in a dependency for it.
    allperms(n) = (collect(p) for p in Iterators.product(ntuple(_ -> 1:n, n)...)
                   if length(unique(p)) == n)

    slow(qperm, nq) = sortperm(map(0:(2^nq-1)) do i
        _MCB.bitstring_to_integer(BitString(nq, i)[qperm])
    end)

    for nq in 1:5, qperm in allperms(nq)
        @test _MCB._index_permutation(qperm, nq) == slow(qperm, nq)
    end
end
