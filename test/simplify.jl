#
# Copyright © 2026 QPerfect. All Rights Reserved.
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
using LinearAlgebra
using Random
using Test
using Symbolics

const _MCB = MimiqCircuitsBase

# Unitary of the gates of `c` on `nq` qubits, in circuit order.
_unitary(c, nq) = _MCB._foldmatrices(
    [ComplexF64.(_MCB.unwrapvalue.(matrix(inst, nq))) for inst in c if getoperation(inst) isa AbstractGate],
    nq, ComplexF64)

_randu(n) = Matrix(qr(randn(ComplexF64, n, n)).Q)

_n2q(c) = count(inst -> numqubits(inst) == 2, c)

function _randcircuit(rng, nq, n)
    c = Circuit()
    for _ in 1:n
        r = rand(rng)
        if r < 0.35
            a, b = randperm(rng, nq)[1:2]
            push!(c, rand(rng, [GateCX(), GateCZ(), GateSWAP(), GateCRZ(0.3), GateRZZ(-0.3)]), a, b)
        elseif r < 0.6
            push!(c, rand(rng, [GateH(), GateX(), GateZ(), GateS(), GateSDG(), GateT(), GateTDG(), GateSX()]), rand(rng, 1:nq))
        else
            push!(c, rand(rng, [GateRZ, GateRX, GateP])(rand(rng, [0.0, 0.25, -0.25, 0.5])), rand(rng, 1:nq))
        end
    end
    return c
end

@testset "created gate matrices" begin
    params = Dict(_MCB._CODE_U => [0.3, 0.7, -1.1, 0.4], _MCB._CODE_P => [0.9],
        _MCB._CODE_RZ => [0.9], _MCB._CODE_RX => [0.9], _MCB._CODE_RY => [0.9])
    for code in instances(_MCB._GateCode)
        p = get(params, code, Float64[])
        @test _MCB._codematrix(code, p) ≈ ComplexF64.(matrix(_MCB._codegate(code, p))) atol = 1e-14
    end
end

@testset "KAK synthesis" begin
    rng = MersenneTwister(1)
    X = ComplexF64[0 1; 1 0]
    Y = ComplexF64[0 -im; im 0]
    CX = ComplexF64[1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 1 0]
    SWAP = ComplexF64[1 0 0 0; 0 0 1 0; 0 1 0 0; 0 0 0 1]
    loc() = kron(_randu(2), _randu(2))

    # (unitary, CX gates it needs)
    cases = Tuple{Matrix{ComplexF64},Int}[]
    for _ in 1:20
        push!(cases, (_randu(4), 3))
        push!(cases, (loc() * loc(), 0))
        push!(cases, (loc() * CX * loc(), 1))
        push!(cases, (loc() * Diagonal([1, 1, 1, -1]) * loc(), 1))
        push!(cases, (loc() * CX * loc() * CX * loc(), 2))
        push!(cases, (loc() * exp(im * (0.3 * kron(X, X) + 0.2 * kron(Y, Y))) * loc(), 2))
        push!(cases, (loc() * SWAP * loc(), 3))
    end
    push!(cases, (Matrix{ComplexF64}(I, 4, 4), 0), (im * CX, 1), (SWAP, 3))

    for (U, k) in cases
        ncx, gates = _MCB._kak_synthesis(U)
        @test ncx == k
        @test count(g -> g[1] == _MCB._CODE_CX, gates) == k
        c = Circuit([Instruction(_MCB._codegate(code, params), qs...) for (code, params, qs) in gates])
        @test _unitary(c, 2) ≈ U atol = 1e-9
    end
end

@testset "remove_identities" begin
    c = Circuit()
    push!(c, GateID(), 1)
    push!(c, GateRZ(0), 1)
    push!(c, GateU(0, 0, 0), 2)
    push!(c, GateCRX(0.0), 1, 2)
    push!(c, GateRX(2π), 1)          # -I: identity only up to a phase
    push!(c, Delay(0.1), 1)          # marks idle time for noise
    @variables θ
    push!(c, GateRZ(θ), 1)
    d = remove_identities(c)
    @test length(d) == 3
    @test getoperation(d[1]) isa GateRX
    @test getoperation(d[2]) isa Delay
end

@testset "cancel_inverses" begin
    # adjacent pairs
    for (a, b) in [(GateH(), GateH()), (GateS(), GateSDG()), (GateT(), GateTDG()), (GateSX(), GateSXDG()),
        (GateRX(0.3), GateRX(-0.3))]
        c = push!(push!(Circuit(), a, 1), b, 1)
        @test isempty(cancel_inverses(c))
    end
    c = push!(push!(Circuit(), GateCX(), 1, 2), GateCX(), 1, 2)
    @test isempty(cancel_inverses(c))

    # written differently but still inverse
    c = push!(push!(Circuit(), GateSWAP(), 1, 2), GateSWAP(), 2, 1)
    @test isempty(cancel_inverses(c))
    c = push!(push!(Circuit(), GateCZ(), 1, 2), GateCZ(), 2, 1)
    @test isempty(cancel_inverses(c))

    # not inverse: different direction
    c = push!(push!(Circuit(), GateCX(), 1, 2), GateCX(), 2, 1)
    @test length(cancel_inverses(c)) == 2

    # through commuting gates: Z on the control, X on the target, disjoint gates
    for (g, q) in [(GateZ(), 1), (GateRZ(0.4), 1), (GateX(), 2), (GateH(), 3)]
        c = push!(Circuit(), GateCX(), 1, 2)
        push!(c, g, q)
        push!(c, GateCX(), 1, 2)
        d = cancel_inverses(c)
        @test length(d) == 1
        @test getoperation(d[1]) == g
    end
    # CX gates sharing a control commute
    c = push!(Circuit(), GateCX(), 1, 2)
    push!(c, GateCX(), 1, 3)
    push!(c, GateCX(), 1, 2)
    @test length(cancel_inverses(c)) == 1

    # blocked by gates that do not commute
    for (g, q) in [(GateX(), 1), (GateH(), 2), (GateZ(), 2)]
        c = push!(Circuit(), GateCX(), 1, 2)
        push!(c, g, q)
        push!(c, GateCX(), 1, 2)
        @test length(cancel_inverses(c)) == 3
    end

    # blocked by non-unitary operations
    for op in [Measure(), Reset()]
        c = push!(Circuit(), GateH(), 1)
        push!(c, op, (op isa Measure ? (1, 1) : (1,))...)
        push!(c, GateH(), 1)
        @test length(cancel_inverses(c)) == 3
    end
    c = push!(Circuit(), GateH(), 1)
    push!(c, Barrier(1), 1)
    push!(c, GateH(), 1)
    @test length(cancel_inverses(c)) == 3
    c = push!(Circuit(), GateX(), 1)
    push!(c, IfStatement(GateX(), BitString("1")), 1, 1)
    push!(c, GateX(), 1)
    @test length(cancel_inverses(c)) == 3

    # a global observable synchronises every wire, even ones it does not declare
    c = push!(Circuit(), GateH(), 2)
    push!(c, Amplitude(BitString("00")), 1)
    push!(c, GateH(), 2)
    @test length(cancel_inverses(c)) == 3

    # a cancellation can expose another
    c = push!(Circuit(), GateH(), 1)
    push!(c, GateS(), 1)
    push!(c, GateSDG(), 1)
    push!(c, GateH(), 1)
    @test isempty(cancel_inverses(c))

    # symbolic: structural inverse, and the diagonal commutation rule
    @variables θ
    c = push!(Circuit(), GateRZ(θ), 1)
    push!(c, GateCZ(), 1, 2)
    push!(c, GateRZ(-θ), 1)
    @test length(cancel_inverses(c)) == 1
end

@testset "multi-controlled X rules" begin
    # wide gates sharing controls commute, beyond the size of a dense check
    c = push!(Circuit(), GateCCX(), 1, 2, 7)
    push!(c, GateCCX(), 1, 3, 8)
    push!(c, GateCCX(), 1, 2, 7)
    @test length(cancel_inverses(c)) == 1

    c = push!(Circuit(), Control(5, GateX()), 1:6...)
    push!(c, GateCZ(), 1, 2)               # diagonal, on controls only
    push!(c, GateT(), 3)
    push!(c, GateX(), 6)                   # X on the target
    push!(c, Control(4, GateX()), 2, 3, 4, 5, 7)   # shares controls, targets differ
    push!(c, Control(5, GateX()), 1:6...)
    d = cancel_inverses(c)
    @test length(d) == 4
    @test count(inst -> getoperation(inst) isa Control{5}, d) == 0

    # controls listed in another order
    c = push!(push!(Circuit(), GateCCX(), 1, 2, 3), GateCCX(), 2, 1, 3)
    @test isempty(cancel_inverses(c))

    # blocked: a target that is the other's control, a diagonal gate on the
    # target, an X rotation on a control
    for (g, qs) in [(GateCCX(), (3, 4, 5)), (GateZ(), (3,)), (GateRX(0.2), (1,))]
        c = push!(Circuit(), GateCCX(), 1, 2, 3)
        push!(c, g, qs...)
        push!(c, GateCCX(), 1, 2, 3)
        @test length(cancel_inverses(c)) == 3
    end

    # agrees with the matrices on small random circuits of these gates
    rng = MersenneTwister(3)
    for _ in 1:50
        c = Circuit()
        for _ in 1:20
            qs = randperm(rng, 4)
            r = rand(rng)
            if r < 0.5
                push!(c, GateCCX(), qs[1:3]...)
            elseif r < 0.7
                push!(c, GateCX(), qs[1:2]...)
            elseif r < 0.85
                push!(c, rand(rng, [GateZ(), GateT(), GateX(), GateSX(), GateRX(0.3)]), qs[1])
            else
                push!(c, GateCZ(), qs[1:2]...)
            end
        end
        @test _unitary(cancel_inverses(c), 4) ≈ _unitary(c, 4)
        @test _unitary(merge_rotations(c), 4) ≈ _unitary(c, 4)
    end
end

@testset "linear synthesis" begin
    rng = MersenneTwister(5)
    for n in (1, 2, 3, 6, 12, 24)
        for _ in 1:10
            c = Circuit()
            for _ in 1:2n^2
                if n > 1 && rand(rng) < 0.8
                    a, b = randperm(rng, n)[1:2]
                    push!(c, rand(rng) < 0.8 ? GateCX() : GateSWAP(), a, b)
                else
                    push!(c, GateX(), rand(rng, 1:n))
                end
            end
            gates = [(_MCB._lineargate(getoperation(inst)), collect(getqubits(inst))) for inst in c]
            A, b = _MCB._affinemap(gates, n)
            cx, xs = _MCB._linear_synthesis(A, b)
            again = vcat([(2, [ctrl, t]) for (ctrl, t) in cx], [(1, [q]) for q in xs])
            @test _MCB._affinemap(again, n) == (A, b)
        end
    end
    @test_throws ArgumentError _MCB._pmh_synthesis(Bool[1 1; 1 1], 1)
end

@testset "resynthesize_linear" begin
    # a block computing the identity disappears
    c = Circuit()
    for q in 1:4
        push!(c, GateCX(), q, q + 1)
    end
    for q in 4:-1:1
        push!(c, GateCX(), q, q + 1)
    end
    @test isempty(resynthesize_linear(c))

    # a ladder applied twice
    c = Circuit()
    for _ in 1:2, q in 1:3
        push!(c, GateCX(), q, q + 1)
    end
    d = resynthesize_linear(c)
    @test _n2q(d) == 2
    @test _unitary(d, 4) ≈ _unitary(c, 4)

    # X gates are kept as the affine part
    c = push!(Circuit(), GateX(), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateCX(), 1, 2)
    d = resynthesize_linear(c)
    @test length(d) == 1
    @test getoperation(d[1]) isa GateX

    # a SWAP is one gate, three CX are not fewer
    c = push!(Circuit(), GateSWAP(), 1, 2)
    @test resynthesize_linear(c) == c

    # blocks end at other gates and keep the circuit's unitary
    rng = MersenneTwister(9)
    for _ in 1:50
        nq = rand(rng, 2:5)
        c = Circuit()
        for _ in 1:40
            r = rand(rng)
            if r < 0.6
                push!(c, GateCX(), randperm(rng, nq)[1:2]...)
            elseif r < 0.7
                push!(c, GateSWAP(), randperm(rng, nq)[1:2]...)
            elseif r < 0.85
                push!(c, GateX(), rand(rng, 1:nq))
            else
                push!(c, GateH(), rand(rng, 1:nq))
            end
        end
        d = resynthesize_linear(c)
        @test _unitary(d, nq) ≈ _unitary(c, nq)
        @test _n2q(d) <= _n2q(c)
    end
end

@testset "merge_rotations" begin
    for G in (GateRX, GateRY, GateRZ, GateP, GateU1)
        c = push!(push!(Circuit(), G(0.1), 1), G(0.2), 1)
        d = merge_rotations(c)
        @test length(d) == 1
        @test getoperation(d[1]) isa G
        @test _MCB.unwrapvalue(only(getparams(d[1]))) ≈ 0.3
    end
    for G in (GateRXX, GateRYY, GateRZZ, GateRZX, GateCRZ, GateCP)
        c = push!(push!(Circuit(), G(0.1), 1, 2), G(0.2), 1, 2)
        d = merge_rotations(c)
        @test length(d) == 1
        @test getoperation(d[1]) isa G
        @test _unitary(d, 2) ≈ _unitary(c, 2)
    end

    # extra parameters must agree
    c = push!(push!(Circuit(), GateR(0.1, 0.5), 1), GateR(0.2, 0.5), 1)
    @test all(_MCB.unwrapvalue.(getparams(only(merge_rotations(c)))) .≈ (0.3, 0.5))
    c = push!(push!(Circuit(), GateR(0.1, 0.5), 1), GateR(0.2, 0.6), 1)
    @test length(merge_rotations(c)) == 2

    # order of the qubits matters for RZX
    c = push!(push!(Circuit(), GateRZX(0.1), 1, 2), GateRZX(0.2), 2, 1)
    @test length(merge_rotations(c)) == 2

    c = push!(push!(Circuit(), RPauli(PauliString("XY"), 0.1), 1, 2), RPauli(PauliString("XY"), 0.2), 1, 2)
    @test length(merge_rotations(c)) == 1

    # a sum to zero removes the pair
    c = push!(push!(Circuit(), GateRZ(0.3), 1), GateRZ(-0.3), 1)
    @test isempty(merge_rotations(c))

    # through commuting gates
    c = push!(Circuit(), GateRZ(0.1), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateRZ(0.2), 1)
    d = merge_rotations(c)
    @test length(d) == 2
    @test _unitary(d, 2) ≈ _unitary(c, 2)

    # gates of one family merge across kinds, into the named gate when there is one
    for (gates, expected) in [((GateT(), GateT()), GateS()), ((GateS(), GateS()), GateZ()),
        ((GateS(), GateZ()), GateSDG()), ((GateT(), GateS()), GateP(3π / 4)),
        ((GateSX(), GateSX()), GateX()), ((GateX(), GateSX()), GateSXDG()),
        ((GateSY(), GateSY()), GateY()), ((GateU1(π / 4), GateT()), GateS())]
        c = Circuit()
        foreach(g -> push!(c, g, 1), gates)
        d = merge_rotations(c)
        @test length(d) == 1
        @test _unitary(d, 1) ≈ matrix(expected)
        expected isa GateP || @test getoperation(d[1]) == expected
    end
    c = Circuit()
    foreach(g -> push!(c, g, 1), (GateT(), GateT(), GateS(), GateZ()))
    @test isempty(merge_rotations(c))                     # P(2π)
    c = push!(push!(Circuit(), GateSX(), 1), GateSXDG(), 1)
    @test isempty(merge_rotations(c))
    # RZ and P differ by a global phase, so they do not merge
    c = push!(push!(Circuit(), GateRZ(0.3), 1), GateP(0.2), 1)
    @test length(merge_rotations(c)) == 2
    # a family member passes a CX control (Z family) or target (X family)
    c = push!(Circuit(), GateT(), 1)
    push!(c, GateSX(), 2)
    push!(c, GateCX(), 1, 2)
    push!(c, GateT(), 1)
    push!(c, GateX(), 2)
    d = merge_rotations(c)
    @test length(d) == 3
    @test _unitary(d, 2) ≈ _unitary(c, 2)

    # the named-gate table agrees with the gates' matrices
    for ((fam, k), op) in _MCB._NAMED_FAMILY_GATES
        f, λ = _MCB._rotationfamily(ComplexF64.(matrix(_MCB._codegate(op, Float64[]))))
        @test f == fam
        @test mod(round(Int, λ / (π / 4)), 8) == k
    end

    # symbolic angles are added symbolically
    @variables θ φ
    c = push!(push!(Circuit(), GateRZ(θ), 1), GateRZ(φ), 1)
    @test isequal(only(getparams(only(merge_rotations(c)))), θ + φ)
    c = push!(push!(Circuit(), GateRZ(θ), 1), GateRZ(-θ), 1)
    @test isempty(merge_rotations(c))
end

@testset "resynthesize_1q" begin
    c = push!(Circuit(), GateH(), 1)
    push!(c, GateS(), 1)
    push!(c, GateH(), 1)
    push!(c, GateX(), 2)
    d = resynthesize_1q(c)
    @test length(d) == 2
    @test getoperation(d[1]) isa GateU
    @test getoperation(d[2]) isa GateX       # single gates stay
    @test _unitary(d, 2) ≈ _unitary(c, 2)

    # a run that multiplies to the identity disappears, one that only gives a
    # phase does not
    c = push!(push!(push!(Circuit(), GateH(), 1), GateZ(), 1), GateH(), 1)
    push!(c, GateX(), 1)
    @test isempty(resynthesize_1q(c))
    c = push!(push!(push!(Circuit(), GateX(), 1), GateY(), 1), GateZ(), 1)
    @test length(resynthesize_1q(c)) == 1

    # runs end at multi-qubit gates, measurements and symbolic gates
    @variables θ
    c = push!(Circuit(), GateH(), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateH(), 1)
    push!(c, Measure(), 1, 1)
    push!(c, GateH(), 1)
    push!(c, GateRZ(θ), 1)
    push!(c, GateH(), 1)
    @test length(resynthesize_1q(c)) == 7
end

@testset "resynthesize_2q" begin
    # four CX on one pair
    c = Circuit()
    for _ in 1:4
        push!(c, GateCX(), 1, 2)
        push!(c, GateRY(0.3), 2)
        push!(c, GateRZ(0.2), 1)
    end
    d = resynthesize_2q(c)
    @test _n2q(d) <= 3
    @test _unitary(d, 2) ≈ _unitary(c, 2)

    # a SWAP written as three CX is already minimal and stays as it is
    c = push!(Circuit(), GateCX(), 1, 2)
    push!(c, GateCX(), 2, 1)
    push!(c, GateCX(), 1, 2)
    @test resynthesize_2q(c) == c

    # blocks on different pairs, with a measurement in between
    c = Circuit()
    for _ in 1:2
        push!(c, GateCX(), 1, 2)
        push!(c, GateCX(), 2, 3)
    end
    push!(c, Measure(), 1, 1)
    push!(c, GateCX(), 1, 2)
    d = resynthesize_2q(c)
    @test count(inst -> getoperation(inst) isa Measure, d) == 1
    @test _unitary(d, 3) ≈ _unitary(c, 3)
end

@testset "simplify" begin
    c = push!(Circuit(), GateCX(), 1, 2)
    push!(c, GateRZ(0.2), 1)
    push!(c, GateCX(), 1, 2)
    push!(c, GateRZ(0.3), 1)
    d = simplify(c)
    @test length(d) == 1
    @test getoperation(d[1]) == GateRZ(0.5)

    # passes can be chosen
    c = push!(push!(push!(Circuit(), GateH(), 1), GateS(), 1), GateH(), 1)
    @test simplify(c; passes=(cancel_inverses,)) == c
    @test length(simplify(c)) == 1

    # the measurement and the bits it writes are kept
    c = push!(Circuit(), GateH(), 1)
    push!(c, Measure(), 1, 1)
    push!(c, GateH(), 1)
    @test simplify(c) == c

    # random circuits: same unitary, never more two-qubit gates
    rng = MersenneTwister(7)
    for _ in 1:50
        nq = rand(rng, 2:4)
        c = _randcircuit(rng, nq, rand(rng, 5:40))
        U = _unitary(c, nq)
        for pass in (DEFAULT_SIMPLIFY_PASSES..., simplify)
            @test _unitary(pass(c), nq) ≈ U atol = 1e-9
        end
        @test _n2q(simplify(c)) <= _n2q(c)
    end
end
