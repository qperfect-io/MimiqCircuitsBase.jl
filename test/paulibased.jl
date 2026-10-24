using Random
using LinearAlgebra
using MimiqCircuitsBase: pstring, unwrapvalue
using Symbolics: Num

# Exact outcome distribution of a circuit made of unitary gates, Measure,
# MeasurePauli, Reset, Not, SetBit0, SetBit1, And, Xor, PrepareStateT
# and IfStatement, by following every measurement and Kraus branch. Only the
# first `keep` bits are reported.
function _pbc_distribution(c, n, nb, ψ0; keep=nb)
    # The matrix of the gate g on the qubits qs of an n-qubit register, cached as
    # it is needed once per branch.
    cache = Dict{Any,Matrix{ComplexF64}}()
    widen(g, qs) = get!(cache, (g, qs)) do
        wide = push!(Circuit(), GateID(), n)
        push!(wide, Instruction(g, qs...))
        ComplexF64.(unwrapvalue.(matrix(wide)))
    end
    embed(K, q) = kron(Matrix{ComplexF64}(I, 2^(q - 1), 2^(q - 1)), K, Matrix{ComplexF64}(I, 2^(n - q), 2^(n - q)))

    function apply(op, qs, bs, (ψ, bits, p))
        if op isa IfStatement
            nop = numbits(getoperation(op))
            cond = bs[(nop+1):end]
            all(i -> bits[cond[i]] == op.bs[i], eachindex(cond)) || return [(ψ, bits, p)]
            return apply(getoperation(op), qs, bs[1:nop], (ψ, bits, p))
        elseif op isa Measure || op isa MeasurePauli
            P = widen(PauliString(op isa Measure ? "Z" : pstring(op)), qs)
            out = []
            for (sgn, val) in ((1, false), (-1, true))
                φ = (ψ + sgn * (P * ψ)) / 2
                w = real(dot(φ, φ))
                w > 1e-14 || continue
                nbits = copy(bits)
                nbits[bs[1]] = val
                push!(out, (φ / sqrt(w), nbits, p * w))
            end
            return out
        elseif op isa Reset
            # Project on Z = ±1 and flip the -1 branch back to |0⟩.
            Z, X = widen(GateZ(), qs), widen(GateX(), qs)
            out = []
            for (sgn, flip) in ((1, false), (-1, true))
                φ = (ψ + sgn * (Z * ψ)) / 2
                w = real(dot(φ, φ))
                w > 1e-14 && push!(out, ((flip ? X * φ : φ) / sqrt(w), bits, p * w))
            end
            return out
        elseif op isa PrepareStateT
            out = []
            for K in krausmatrices(op)
                φ = embed(ComplexF64.(unwrapvalue.(K)), qs[1]) * ψ
                w = real(dot(φ, φ))
                w > 1e-14 && push!(out, (φ / sqrt(w), bits, p * w))
            end
            return out
        elseif op isa Not
            nbits = copy(bits)
            nbits[bs[1]] = !nbits[bs[1]]
            return [(ψ, nbits, p)]
        elseif op isa SetBit0 || op isa SetBit1
            nbits = copy(bits)
            nbits[bs[1]] = op isa SetBit1
            return [(ψ, nbits, p)]
        elseif op isa And
            nbits = copy(bits)
            nbits[bs[1]] = all(i -> bits[i], bs[2:end])
            return [(ψ, nbits, p)]
        elseif op isa Xor
            nbits = copy(bits)
            nbits[bs[1]] = isodd(count(i -> bits[i], bs[2:end]))
            return [(ψ, nbits, p)]
        else
            return [(widen(op, qs) * ψ, bits, p)]
        end
    end

    branches = [(ψ0, falses(nb), 1.0)]
    for inst in c
        qs, bs = getqubits(inst), getbits(inst)
        branches = reduce(vcat, [apply(getoperation(inst), qs, bs, br) for br in branches])
    end

    dist = Dict{BitVector,Float64}()
    for (_, bits, p) in branches
        key = bits[1:keep]
        dist[key] = get(dist, key, 0.0) + p
    end
    return dist
end

function _same_distribution(a, b; atol=1e-9)
    return all(k -> isapprox(get(a, k, 0.0), get(b, k, 0.0); atol=atol), union(keys(a), keys(b)))
end

function _randstate(rng, n)
    ψ = randn(rng, ComplexF64, 2^n)
    return ψ / norm(ψ)
end

@testset "MeasurePauli" begin
    @test_throws ArgumentError MeasurePauli("III")
    @test_throws ArgumentError MeasurePauli("XA")
    @test numqubits(MeasurePauli("XIZ")) == 3
    @test numbits(MeasurePauli("XIZ")) == 1
    @test MeasurePauli("XY") == MeasurePauli(PauliString("XY"))
    @test_throws ErrorException inverse(MeasurePauli("X"))

    c = push!(Circuit(), MeasurePauli("XIYZ"), 4, 2, 1, 3, 2)
    testsaveloadproto(c)

    # The canonical decomposition must give the same outcome statistics.
    rng = MersenneTwister(1)
    for s in ["Z", "X", "Y", "XZ", "ZX", "YY", "XIZ", "IYI", "ZXYI", "IIXY"]
        n = length(s)
        qs = randperm(rng, n)
        m = push!(Circuit(), MeasurePauli(s), qs..., 1)
        ψ = _randstate(rng, n)
        @test _same_distribution(
            _pbc_distribution(m, n, 1, ψ),
            _pbc_distribution(decompose(m), n, 1, ψ),
        )
    end

    # The Y rotation uses SDG, H and S, so the QASM basis decomposes it; the
    # Stim and Clifford+T bases keep it as MPP.
    m = push!(Circuit(), MeasurePauli("XYZ"), 1, 2, 3, 1)
    ψ = _randstate(rng, 3)
    for basis in (StimBasis(), QASMBasis(), CliffordTBasis())
        d = decompose(m; basis=basis)
        @test _same_distribution(_pbc_distribution(m, 3, 1, ψ), _pbc_distribution(d, 3, 1, ψ))
    end
    @test getoperation.(collect(decompose_step(MeasurePauli("Y")))) == [GateSDG(), GateH(), Measure(), GateH(), GateS()]
end

@testset "pauli_based_computation" begin
    c = push!(Circuit(), GateH(), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateT(), 2)
    push!(c, Measure(), 1:2, 1:2)
    p = pauli_based_computation(c)
    @test length(p) == 3
    @test pstring(getoperation(p[1]).pauli) == "XZ"
    @test unwrapvalue(getoperation(p[1]).θ) ≈ π / 4
    @test getoperation(p[2]) == MeasurePauli("X")
    @test getoperation(p[3]) == MeasurePauli("XZ")

    # A negated observable flips the measured bit.
    c = push!(Circuit(), GateX(), 1)
    push!(c, Measure(), 1, 1)
    p = pauli_based_computation(c)
    @test getoperation.(collect(p)) == [MeasurePauli("Z"), Not()]

    @test_throws ArgumentError pauli_based_computation(
        push!(Circuit(), GateRX(0.3), 1);
        basis=CanonicalBasis(),
    )

    # Random Clifford+T circuits with mid-circuit measurements: the rewritten
    # circuit has no Clifford left and reproduces the outcome statistics on a
    # random input state.
    gates1 = [GateH(), GateS(), GateSDG(), GateT(), GateTDG(), GateX(), GateY(), GateZ(), GateSX(), GateSYDG()]
    gates2 = [GateCX(), GateCZ(), GateCY(), GateSWAP(), GateISWAP(), GateECR(), GateDCX()]
    rng = MersenneTwister(42)
    n, nb = 3, 5
    for _ in 1:20
        c = Circuit()
        b = 0
        for _ in 1:30
            r = rand(rng)
            if r < 0.5
                push!(c, rand(rng, gates1), rand(rng, 1:n))
            elseif r < 0.9
                push!(c, rand(rng, gates2), randperm(rng, n)[1:2]...)
            elseif b < nb - n
                push!(c, rand(rng, [Measure(), MeasureX(), MeasureY()]), rand(rng, 1:n), b += 1)
            end
        end
        push!(c, GateCCX(), randperm(rng, n)...)
        push!(c, MeasurePauli("XYZ"), 1:n..., b += 1)
        for q in 1:(nb-b)
            push!(c, Measure(), mod1(q, n), b + q)
        end

        p = pauli_based_computation(c)
        @test all(i -> getoperation(i) isa Union{RPauli,MeasurePauli,Not}, p)
        @test all(i -> !(getoperation(i) isa RPauli) || abs(unwrapvalue(getoperation(i).θ)) ≈ π / 4, p)

        ψ = _randstate(rng, n)
        ref = decompose(c)
        @test _same_distribution(_pbc_distribution(ref, n, nb, ψ), _pbc_distribution(p, n, nb, ψ))
    end

    # The angles are exact multiples of π and survive a proto round trip
    # unchanged.
    @test all(i -> !(getoperation(i) isa RPauli) ||
                   any(a -> isequal(getoperation(i).θ, a), (Num(π) / 4, -Num(π) / 4)), p)
    @test saveloadproto(p) == p
end

@testset "PrepareStateT" begin
    m = [1, cis(π / 4)] ./ sqrt(2)
    Ks = [ComplexF64.(unwrapvalue.(K)) for K in krausmatrices(PrepareStateT())]
    @test sum(K' * K for K in Ks) ≈ I
    # Any input state ends up in |m⟩⟨m|.
    rng = MersenneTwister(3)
    for _ in 1:5
        ψ = _randstate(rng, 1)
        @test sum(K * ψ * ψ' * K' for K in Ks) ≈ m * m'
    end
    # The canonical decomposition, Reset then H then T, prepares the same state.
    d = decompose_step(PrepareStateT())
    @test getoperation.(collect(d)) == [Reset(), GateH(), GateT()]
    @test ComplexF64.(unwrapvalue.(matrix(GateT()) * matrix(GateH()))) * [1, 0] ≈ m
    @test_throws ErrorException inverse(PrepareStateT())
    testsaveloadproto(push!(Circuit(), PrepareStateT(), 2))
end

@testset "pauli_based_computation with magic states" begin
    # Each π/8 rotation becomes PrepareStateT, a P⊗Z measurement and an X or Y
    # measurement of the ancilla chosen by the corrected outcome.
    c = push!(Circuit(), GateH(), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateT(), 2)
    push!(c, Measure(), 1:2, 1:2)
    p = pauli_based_computation(c; magic_states=true)
    @test numqubits(p) == 3
    @test count(i -> getoperation(i) isa PrepareStateT, p) == 1
    @test !any(i -> getoperation(i) isa Union{RPauli,GateT,GateTDG}, p)

    # Without T gates nothing changes.
    c = push!(Circuit(), GateH(), 1)
    push!(c, Measure(), 1, 1)
    @test pauli_based_computation(c; magic_states=true) == pauli_based_computation(c)

    # Random Clifford+T circuits with mid-circuit measurements: the injected
    # circuit reproduces the statistics of the original bits. Kept small, as
    # every injection doubles the branches three times.
    gates1 = [GateH(), GateS(), GateSDG(), GateT(), GateTDG(), GateX(), GateY(), GateZ(), GateSX()]
    gates2 = [GateCX(), GateCZ(), GateCY(), GateSWAP(), GateISWAP()]
    rng = MersenneTwister(7)
    n, nb = 3, 4
    ntested = 0
    for _ in 1:40
        c = Circuit()
        b = 0
        for _ in 1:14
            r = rand(rng)
            if r < 0.55
                push!(c, rand(rng, gates1), rand(rng, 1:n))
            elseif r < 0.92
                push!(c, rand(rng, gates2), randperm(rng, n)[1:2]...)
            elseif b < nb - n
                push!(c, rand(rng, [Measure(), MeasureX(), MeasureY()]), rand(rng, 1:n), b += 1)
            end
        end
        for q in 1:(nb-b)
            push!(c, Measure(), mod1(q, n), b + q)
        end
        count(i -> getoperation(i) isa Union{GateT,GateTDG}, c) in 1:4 || continue
        ntested += 1

        p = pauli_based_computation(c; magic_states=true)
        @test !any(i -> getoperation(i) isa Union{RPauli,GateT,GateTDG}, p)

        ψ = _randstate(rng, n)
        ψanc = kron(ψ, [1.0, 0.0])
        ref = decompose(c)
        @test _same_distribution(
            _pbc_distribution(ref, n, nb, ψ),
            _pbc_distribution(p, n + 1, numbits(p), ψanc; keep=nb),
        )
    end
    @test ntested >= 15
    @test saveloadproto(p) == p

    # The frame is updated and read with 3-bit Xor only, so the classical
    # operations keep the same arities however long the circuit is.
    rng = MersenneTwister(11)
    n = 12
    c = Circuit()
    for _ in 1:600
        if rand(rng) < 0.6
            push!(c, rand(rng, [GateH(), GateS(), GateT(), GateTDG()]), rand(rng, 1:n))
        else
            push!(c, GateCX(), randperm(rng, n)[1:2]...)
        end
    end
    push!(c, Measure(), 1:n, 1:n)
    p = pauli_based_computation(c; magic_states=true)
    classical = [getoperation(i) for i in p if getoperation(i) isa AbstractClassical]
    @test count(op -> op isa Xor, classical) > 100
    @test Set(numbits.(classical)) ⊆ Set([1, 3])
    @test all(op -> op isa Union{Xor{3},Not}, classical)
    @test saveloadproto(p) == p
end

# Expands measurements and resets into Clifford gates around Measure, Reset or
# MeasureReset, and keeps everything else, conditional operations included,
# unchanged.
struct _ExpandMeasurements <: DecompositionBasis end

const _NATIVE_MEASUREMENTS = Union{
    MeasureX,MeasureY,MeasureXX,MeasureYY,MeasureZZ,MeasurePauli,
    ResetX,ResetY,MeasureReset,MeasureResetX,MeasureResetY,
}

MimiqCircuitsBase.isterminal(::_ExpandMeasurements, op::Operation) = !(op isa _NATIVE_MEASUREMENTS)
MimiqCircuitsBase.decompose!(builder, ::_ExpandMeasurements, op::Operation, qt, ct, zt) =
    decompose_step!(builder, CanonicalRewrite(), op, qt, ct, zt)

# A random operation made of Pauli operators only, and its number of qubits.
function _random_pauli_body(rng)
    r = rand(rng, 1:6)
    r == 1 && return rand(rng, [GateX(), GateY(), GateZ()]), 1
    r == 2 && return PauliString(String(rand(rng, collect("IXYZ"), 3))), 3
    r == 4 && return Parallel(2, rand(rng, [GateX(), GateY(), GateZ()])), 2
    r == 5 && return Repeat(rand(rng, 2:3), PauliString("XZ")), 2
    k = rand(rng, 2:3)
    body = push!(Circuit(), GateID(), k)
    for _ in 1:3
        push!(body, rand(rng, [GateX(), GateY(), GateZ(), GateID()]), rand(rng, 1:k))
    end
    r == 3 && return Block(body), k
    return GateCall(GateDecl(:paulis, (), body)), k
end

# A random 3-qubit circuit with mid-circuit measurements (some native, some that
# also reset), resets, and conditional Paulis on the measured bits, followed by a
# measurement of every qubit into the last `n` of the `nb` bits. With `condt`,
# some conditional bodies are T or T† gates.
function _random_conditional_circuit(rng, nsteps, nmid; condt=false, maxt=100)
    n = 3
    gates1 = [GateH(), GateS(), GateSDG(), GateT(), GateTDG(), GateX(), GateY(), GateSX()]
    gates2 = [GateCX(), GateCZ(), GateCY(), GateSWAP(), GateISWAP()]
    measures1 = [Measure(), MeasureX(), MeasureY(), MeasureReset(), MeasureResetX(), MeasureResetY()]
    measures2 = [MeasureXX(), MeasureYY(), MeasureZZ(), MeasurePauli("XY")]
    c = Circuit()
    b = 0
    nt = 0
    for _ in 1:nsteps
        r = rand(rng)
        if r < 0.3
            g = rand(rng, gates1)
            if g isa Union{GateT,GateTDG}
                nt < maxt || continue
                nt += 1
            end
            push!(c, g, rand(rng, 1:n))
        elseif r < 0.45
            push!(c, rand(rng, gates2), randperm(rng, n)[1:2]...)
        elseif r < 0.6 && b < nmid
            if rand(rng) < 0.7
                push!(c, rand(rng, measures1), rand(rng, 1:n), b += 1)
            else
                push!(c, rand(rng, measures2), randperm(rng, n)[1:2]..., b += 1)
            end
        elseif r < 0.68
            push!(c, rand(rng, [Reset(), ResetX(), ResetY()]), rand(rng, 1:n))
        elseif b > 0
            k = rand(rng, 1:min(b, 3))
            cbits = randperm(rng, b)[1:k]
            pattern = BitString(String(rand(rng, ['0', '1'], k)))
            if condt && rand(rng) < 0.25
                body, w = rand(rng, [GateT(), GateTDG()]), 1
            else
                body, w = _random_pauli_body(rng)
            end
            push!(c, IfStatement(body, pattern), randperm(rng, n)[1:w]..., cbits...)
        end
    end
    push!(c, Measure(), 1:n, (b+1):(b+n))
    return c
end

@testset "pauli_based_computation with conditionals and resets" begin
    # A conditional Pauli product stays one conditional Pauli string, however
    # its body is written.
    body = push!(Circuit(), GateX(), 1)
    push!(body, GateZ(), 2)
    push!(body, GateY(), 3)
    for op in (Block(body), GateCall(GateDecl(:xzy, (), body)))
        c = push!(Circuit(), Measure(), 1, 1)
        push!(c, GateH(), 2)
        push!(c, IfStatement(op, bs"1"), 1, 2, 3, 1)
        p = pauli_based_computation(c)
        ifs = [i for i in p if getoperation(i) isa IfStatement]
        @test length(ifs) == 1
        @test getoperation(ifs[1]) == IfStatement(PauliString("XXY"), bs"1")
        @test getqubits(ifs[1]) == (1, 2, 3)
        @test getbits(ifs[1]) == (1,)
    end

    # A product equal to the identity leaves nothing behind.
    c = push!(Circuit(), Measure(), 1, 1)
    push!(c, IfStatement(Repeat(2, PauliString("XZ")), bs"1"), 1, 2, 1)
    @test pauli_based_computation(c) == push!(Circuit(), MeasurePauli("Z"), 1, 1)

    # A reset measures into a new bit after the circuit's bits, then flips the
    # qubit back when the outcome is 1. MeasureReset uses the given bit.
    p = pauli_based_computation(push!(Circuit(), ResetX(), 1))
    @test getoperation.(collect(p)) == [MeasurePauli("X"), IfStatement(PauliString("Z"), bs"1")]
    @test getbits.(collect(p)) == [(1,), (1,)]
    c = push!(Circuit(), Measure(), 1, 1)
    push!(c, Reset(), 1)
    push!(c, MeasureResetY(), 1, 2)
    p = pauli_based_computation(c)
    @test getoperation.(collect(p)) == [
        MeasurePauli("Z"), MeasurePauli("Z"), IfStatement(PauliString("X"), bs"1"),
        MeasurePauli("Y"), IfStatement(PauliString("X"), bs"1"),
    ]
    @test getbits.(collect(p)) == [(1,), (3,), (3,), (2,), (2,)]

    # With magic states, a condition on several bits is reduced to the bit
    # after the frame, and bits compared with 0 are restored afterwards.
    c = push!(Circuit(), Measure(), 1:2, 1:2)
    push!(c, IfStatement(GateX(), bs"01"), 1, 1, 2)
    p = pauli_based_computation(c; magic_states=true)
    @test getoperation.(collect(p))[3:end] == [SetBit1(), Not(), And(), Not(), And(), Xor()]
    @test getbits.(collect(p))[3:end] == [(7,), (1,), (7, 7, 1), (1,), (7, 7, 2), (3, 3, 7)]

    # A conditional T becomes a conditional rotation; a conditional Clifford
    # and a conditional magic-state injection are refused.
    c = push!(Circuit(), Measure(), 1, 1)
    push!(c, GateH(), 2)
    push!(c, IfStatement(GateTDG(), bs"0"), 2, 1)
    p = pauli_based_computation(c)
    @test getoperation(p[2]) == IfStatement(RPauli("X", -Num(π) / 4), bs"0")
    @test_throws r"Clifford accumulated after it would depend on the condition bits" pauli_based_computation(
        push!(Circuit(), IfStatement(GateH(), bs"1"), 1, 1))
    @test_throws ArgumentError pauli_based_computation(push!(Circuit(), IfStatement(GateCX(), bs"1"), 1, 2, 1))
    @test_throws r"magic state cannot be injected conditionally" pauli_based_computation(
        c; magic_states=true)
    @test_throws ArgumentError pauli_based_computation(push!(Circuit(), IfStatement(Measure(), bs"1"), 1, 1, 2))

    # Random circuits with conditionals and resets reproduce the statistics of
    # the original bits, in both modes.
    rng = MersenneTwister(5)
    for i in 1:30
        condt = isodd(i)
        c = _random_conditional_circuit(rng, 24, 4; condt=condt)
        nb = numbits(c)
        ψ = _randstate(rng, 3)
        ref = _pbc_distribution(decompose(decompose(c; basis=_ExpandMeasurements())), 3, nb, ψ)

        p = pauli_based_computation(c)
        @test all(i -> getoperation(i) isa Union{RPauli,MeasurePauli,Not,IfStatement}, p)
        @test _same_distribution(ref, _pbc_distribution(p, 3, numbits(p), ψ; keep=nb))
        @test saveloadproto(p) == p

        # The pass reads measurements and resets directly; expanding them into
        # Clifford gates first gives the same circuit.
        expanded = decompose(c; basis=_ExpandMeasurements())
        @test pauli_based_computation(expanded) == p
    end
    ntested = 0
    for _ in 1:40
        c = _random_conditional_circuit(rng, 18, 3; maxt=2)
        count(i -> getoperation(i) isa Union{GateT,GateTDG}, c) > 0 || continue
        ntested += 1
        nb = numbits(c)
        ψ = _randstate(rng, 3)
        ref = _pbc_distribution(decompose(decompose(c; basis=_ExpandMeasurements())), 3, nb, ψ)

        p = pauli_based_computation(c; magic_states=true)
        @test !any(i -> getoperation(i) isa Union{RPauli,GateT,GateTDG}, p)
        @test _same_distribution(ref, _pbc_distribution(p, 4, numbits(p), kron(ψ, [1.0, 0.0]); keep=nb))
        expanded = decompose(c; basis=_ExpandMeasurements())
        @test pauli_based_computation(expanded; magic_states=true) == p
        @test saveloadproto(p) == p
    end
    @test ntested >= 20
end
