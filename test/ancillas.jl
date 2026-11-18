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
using Random
using LinearAlgebra: norm
using MimiqCircuitsBase
import MimiqCircuitsBase: unwrapvalue, isterminal

function _roundtrip(c)
    mktemp() do fname, _
        saveproto(fname, c)
        return loadproto(fname, Circuit)
    end
end

_mat(c) = ComplexF64.(unwrapvalue.(matrix(c)))
_count(c, T) = count(inst -> getoperation(inst) isa T, c)
_tcount(c) = _count(c, Union{GateT,GateTDG})

# A C_n(X) on qubits 1:n+1 in a circuit `extra` qubits wider.
function _cnx_circuit(n, extra)
    c = push!(Circuit(), Control(n, GateX()), 1:n+1...)
    extra > 0 && push!(c, GateID(), n + 1 + extra)
    return c
end

@testset "Borrowed qubits" begin
    @testset "defaults leave the output unchanged" begin
        c = _cnx_circuit(4, 2)
        @test decompose(c) == decompose(c; basis=CanonicalBasis(borrow=false))
        @test CanonicalBasis() == CanonicalBasis(borrow=false)
        @test CliffordTBasis(borrow=true) != CliffordTBasis()
    end

    @testset "C$(n)X keeps its unitary" for n in 3:5, extra in 1:n-2
        c = _cnx_circuit(n, extra)
        b = decompose(c; basis=CanonicalBasis(borrow=true))
        @test isapprox(_mat(b), _mat(c); atol=1e-8)
        w = decompose(c; basis=CanonicalBasis(borrow=true), wrap=true)
        @test isapprox(_mat(decompose(w)), _mat(c); atol=1e-8)
    end

    @testset "gate counts per basis" begin
        for n in 4:7
            c = _cnx_circuit(n, 1)
            @test _count(decompose(c; basis=CanonicalBasis(borrow=true)), GateCX) <
                  _count(decompose(c; basis=CanonicalBasis()), GateCX)
            @test _count(decompose(c; basis=QASMBasis(borrow=true)), GateCCX) <= 8 * (n - 2)
            @test _count(decompose(c; basis=RuleBasis(CanonicalRewrite())), GateCX) ==
                  _count(decompose(c; basis=CanonicalBasis()), GateCX)
        end

        # Lemma 7.2: n-2 borrowed qubits give 4(n-2) Toffolis, 7 T each.
        # QASMBasis keeps C3X, so its counts start at n = 4.
        for n in 3:7
            c = _cnx_circuit(n, n - 2)
            n >= 4 && @test _count(decompose(c; basis=QASMBasis(borrow=true)), GateCCX) == 4 * (n - 2)
            @test _tcount(decompose(c; basis=CliffordTBasis(borrow=true))) == 28 * (n - 2)
        end
    end

    @testset "nearest qubits are borrowed first" begin
        c = push!(Circuit(), GateID(), 1)
        push!(c, Control(4, GateX()), 4:8...)
        push!(c, GateID(), 12)
        b = decompose(c; basis=QASMBasis(borrow=true))
        used = setdiff(Set(q for inst in b for q in getqubits(inst)), Set([1, 12, 4, 5, 6, 7, 8]))
        @test used == Set([3, 9])
    end

    @testset "no width, no borrowing" begin
        op = Control(4, GateX())
        @test decompose(op; basis=CanonicalBasis(borrow=true)) == decompose(op)
        inst = Instruction(op, 1, 2, 3, 4, 5)
        @test numqubits(decompose(inst; basis=CanonicalBasis(borrow=true))) == 5
    end

    @testset "conditional gates borrow too" begin
        c = push!(Circuit(), IfStatement(Control(4, GateX()), bs"1"), 1:5..., 1)
        push!(c, GateID(), 7)
        b = decompose(c; basis=QASMBasis(borrow=true))
        @test all(inst -> getoperation(inst) isa Union{IfStatement,GateID}, b)
        @test _count(b, IfStatement) == 8
    end

    @testset "wrap" begin
        c = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(c, Control(4, GateX()), 3:7...)
        push!(c, GateID(), 9)
        w = decompose(c; basis=CanonicalBasis(borrow=true), wrap=true)
        # The body uses the two borrowed qubits as targets 6 and 7.
        @test numqubits(w[1]) == 7
        @test getqubits(w[1])[1:5] == (1, 2, 3, 4, 5)
        @test getqubits(w[2])[1:5] == (3, 4, 5, 6, 7)
        @test isempty(intersect(getqubits(w[2])[6:7], 3:7))
        # Both calls share one declaration.
        @test getoperation(w[1])._decl === getoperation(w[2])._decl
        @test isapprox(_mat(decompose(w)), _mat(c); atol=1e-8)
    end

    @testset "losses refuse borrowing" begin
        c = push!(Circuit(), Loss(), 6)
        append!(c, _cnx_circuit(4, 1))
        @test_throws ArgumentError decompose(c; basis=CanonicalBasis(borrow=true))
        r = push!(Circuit(), IfStatement(Reload(), bs"1"), 6, 1)
        append!(r, _cnx_circuit(4, 1))
        @test_throws ArgumentError decompose(r; basis=CanonicalBasis(borrow=true))
        @test decompose(c) isa Circuit

        # Losses nested in other operations count too.
        lossy = Block(push!(Circuit(), Loss(), 1))
        for op in (Repeat(2, lossy), BlockDecl(:lossy, (), lossy)(), WhileStatement(lossy, bs"1"))
            n = push!(Circuit(), op, 6, (numbits(op) > 0 ? (1,) : ())...)
            append!(n, _cnx_circuit(4, 1))
            @test_throws ArgumentError decompose(n; basis=CanonicalBasis(borrow=true))
        end
    end

    @testset "C_n(X) without free qubits" begin
        # The ancilla-free branch of the Barenco construction.
        b = MimiqCircuitsBase._controlx_decompose!(Circuit(), [1, 2, 3, 4], 5, Int[])
        @test isapprox(_mat(decompose(b)), _mat(push!(Circuit(), Control(4, GateX()), 1:5...)); atol=1e-8)
    end
end

@testset "Ancilla markers and numancillas" begin
    @testset "markers" begin
        c = push!(Circuit(), AncillaAlloc(), 3)
        push!(c, GateX(), 3)
        push!(c, GateX(), 3)
        push!(c, AncillaFree(), 3)
        @test sprint(show, AncillaAlloc()) == "AncillaAlloc"
        @test isunitary(AncillaAlloc()) && isunitary(AncillaFree())
        @test _roundtrip(c) == c
        for basis in (CanonicalBasis(), CliffordTBasis(), QASMBasis(), StimBasis(), FlattenedBasis())
            @test isterminal(basis, AncillaAlloc())
            @test isterminal(basis, AncillaFree())
        end
        # Lost is terminal in QASMBasis too.
        @test decompose(push!(Circuit(), Lost(), 1); basis=QASMBasis()) == push!(Circuit(), Lost(), 1)
    end

    @testset "pauli_based_computation drops the markers" begin
        c = push!(Circuit(), AncillaAlloc(), 2)
        push!(c, GateH(), 1)
        push!(c, GateCX(), 1, 2)
        push!(c, GateT(), 2)
        push!(c, GateCX(), 1, 2)
        push!(c, AncillaFree(), 2)
        push!(c, Tick())
        pbc = pauli_based_computation(c)
        @test !any(inst -> getoperation(inst) isa Union{AncillaAlloc,AncillaFree}, pbc)
        @test any(inst -> getoperation(inst) isa Tick, pbc)
    end

    body = push!(Circuit(), GateCCX(), 1, 2, 3)
    push!(body, GateCX(), 3, 4)
    push!(body, GateCCX(), 1, 2, 3)

    @testset "GateDecl" begin
        d = GateDecl(:and, (), body; numancillas=1)
        @test numancillas(d) == 1
        @test numancillas(d()) == 1
        @test numancillas(GateDecl(:and, (), body)) == 0
        @test d != GateDecl(:and, (), body)
        @test d == GateDecl(:and, (), body; numancillas=1)
        @test_throws ArgumentError GateDecl(:and, (), body; numancillas=5)
        @test_throws ArgumentError GateDecl(:and, (), body; numancillas=-1)
        c = push!(Circuit(), d(), 1:4...)
        @test numancillas(getoperation(_roundtrip(c)[1])) == 1
        @test numancillas(GateH()) == 0
    end

    @testset "Block" begin
        b = Block(body; numancillas=1)
        @test numancillas(b) == 1
        @test b != Block(body)
        @test numancillas(Block(4, 0, 0, body._instructions; numancillas=2)) == 2
        @test_throws ArgumentError Block(body; numancillas=5)
        c = push!(Circuit(), b, 1:4...)
        @test numancillas(getoperation(_roundtrip(c)[1])) == 1
    end

    @testset "BlockDecl" begin
        d = BlockDecl(:and, (), body; numancillas=1)
        @test numancillas(d) == 1
        @test numancillas(d()) == 1
        @test d != BlockDecl(:and, (), body)
        @test numancillas(BlockDecl(:and, (), Block(body; numancillas=2))) == 2
        c = push!(Circuit(), d(), 1:4...)
        @test numancillas(getoperation(_roundtrip(c)[1])) == 1
    end
end

# `d` on qubits 1:M acts on 1:N as `c` does, for every input with the qubits
# N+1:M in |0⟩, and returns those qubits to |0⟩. Qubit 1 is the most
# significant bit of a matrix index, so these inputs are x * 2^(M-N).
function _acts_as(d, c, N)
    strip = Circuit([inst for inst in d if !(getoperation(inst) isa AbstractAnnotation)])
    M = max(numqubits(d), N)
    V = numqubits(strip) < M ? _mat(push!(strip, GateID(), M)) : _mat(strip)
    U = numqubits(c) < N ? _mat(push!(copy(c), GateID(), N)) : _mat(c)
    sel = [x * 2^(M - N) + 1 for x in 0:2^N-1]
    return isapprox(V[sel, sel], U; atol=1e-8) && isapprox(norm(V[sel, sel]), 2^(N / 2); atol=1e-8)
end

@testset "Clean ancillas" begin
    @testset "C$(n)X with $m ancillas" for n in 3:5, m in 1:n-2
        c = push!(Circuit(), Control(n, GateX()), 1:n+1...)
        d = decompose(c; basis=CanonicalBasis(max_ancillas=m))
        @test ancillas(d) == collect(n+2:n+1+m)
        @test check_ancillas(d) === nothing
        @test _acts_as(d, c, n + 1)
    end

    @testset "T counts" begin
        for n in 3:7
            c = push!(Circuit(), Control(n, GateX()), 1:n+1...)
            # n-2 relative-phase Toffolis twice (4 T each) and one Toffoli.
            @test _tcount(decompose(c; basis=CliffordTBasis(max_ancillas=n - 2))) == 8 * (n - 2) + 7
            # A larger budget does not change the result.
            @test _tcount(decompose(c; basis=CliffordTBasis(max_ancillas=n))) == 8 * (n - 2) + 7
        end
    end

    @testset "freed ancillas are reused" begin
        c = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(c, Control(4, GateX()), 2:6...)
        d = decompose(c; basis=CanonicalBasis(max_ancillas=2))
        @test ancillas(d) == [7, 8]
        @test numqubits(d) == 8
        @test _acts_as(d, c, 6)
    end

    @testset "markers of the input are read" begin
        # max_ancillas bounds the new qubits; freed ones of the input come on top.
        c = push!(Circuit(), AncillaAlloc(), 5)
        push!(c, GateX(), 5)
        push!(c, GateX(), 5)
        push!(c, AncillaFree(), 5)
        push!(c, Control(3, GateX()), 1:4...)
        d = decompose(c; basis=CanonicalBasis(max_ancillas=1))
        # Qubit 5 is free again after its window, and is used before a new one.
        @test ancillas(d) == [5]
        @test numqubits(d) == 5

        # Touched after its window, it is no longer known to be in |0⟩.
        push!(c, GateH(), 5)
        push!(c, Control(3, GateX()), 1:4...)
        d = decompose(c; basis=CanonicalBasis(max_ancillas=1))
        @test ancillas(d) == [5, 6]

        # Nested windows: the qubit is free only once both are closed.
        n = push!(Circuit(), AncillaAlloc(), 5)
        push!(n, AncillaAlloc(), 5)
        push!(n, AncillaFree(), 5)
        push!(n, Control(3, GateX()), 1:4...)
        push!(n, AncillaFree(), 5)
        push!(n, Control(3, GateX()), 1:4...)
        d = decompose(n; basis=CanonicalBasis(max_ancillas=1))
        allocs(q) = count(inst -> getoperation(inst) isa AncillaAlloc && getqubit(inst, 1) == q, d)
        @test allocs(6) == 1
        @test allocs(5) == 3
    end

    @testset "clean ancillas before borrowed qubits" begin
        c = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(c, GateID(), 7)
        d = decompose(c; basis=CanonicalBasis(borrow=true, max_ancillas=2))
        @test ancillas(d) == [8, 9]
        @test !any(inst -> 6 in getqubits(inst), d)
    end

    @testset "conditional gates" begin
        c = push!(Circuit(), IfStatement(Control(4, GateX()), bs"1"), 1:5..., 1)
        d = decompose(c; basis=QASMBasis(max_ancillas=2))
        markers = filter(inst -> getoperation(inst) isa Union{AncillaAlloc,AncillaFree}, d._instructions)
        @test length(markers) == 4
        @test all(inst -> getoperation(inst) isa Union{IfStatement,AncillaAlloc,AncillaFree}, d)
        @test check_ancillas(d) === nothing
    end

    @testset "wrap" begin
        c = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(c, Control(4, GateX()), 2:6...)
        w = decompose(c; basis=CanonicalBasis(max_ancillas=2), wrap=true)
        @test check_ancillas(w) === nothing
        calls = filter(inst -> getoperation(inst) isa GateCall, w._instructions)
        @test length(calls) == 2
        @test all(inst -> numancillas(getoperation(inst)) == 2, calls)
        @test getqubits(calls[1]) == (1, 2, 3, 4, 5, 7, 8)
        @test getoperation(calls[1])._decl === getoperation(calls[2])._decl
        # The declaration body has no markers.
        @test !any(inst -> getoperation(inst) isa AbstractAnnotation, getoperation(calls[1])._decl)
        @test _acts_as(decompose(w), c, 6)

        # Borrowed and clean qubits together: data, borrowed, clean.
        c = push!(Circuit(), Control(5, GateX()), 1:6...)
        push!(c, GateID(), 7)
        w = decompose(c; basis=CanonicalBasis(borrow=true, max_ancillas=1), wrap=true)
        call = only(filter(inst -> numancillas(getoperation(inst)) > 0, w._instructions))
        @test numancillas(getoperation(call)) == 1
        @test getqubits(call)[end] == 8
        @test _acts_as(decompose(w), c, 7)
    end

    @testset "merge_ancilla_windows" begin
        c = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(c, Control(4, GateX()), 1:5...)
        w = decompose(c; basis=CanonicalBasis(max_ancillas=2), wrap=true)
        m = merge_ancilla_windows(w)
        @test length(m) == length(w) - 4
        @test getoperation(m[3]) isa GateCall && getoperation(m[4]) isa GateCall
        @test check_ancillas(m) === nothing

        # Something on the wire in between keeps the windows apart.
        k = push!(Circuit(), AncillaFree(), 1)
        push!(k, GateX(), 1)
        push!(k, AncillaAlloc(), 1)
        @test length(merge_ancilla_windows(k)) == 3
    end

    @testset "check_ancillas" begin
        @test_throws ArgumentError check_ancillas(push!(Circuit(), AncillaFree(), 1))
        @test_throws ArgumentError check_ancillas(push!(Circuit(), AncillaAlloc(), 1))
        decl = GateDecl(:and, (), push!(Circuit(), GateCCX(), 1, 2, 3); numancillas=1)
        @test_throws ArgumentError check_ancillas(push!(Circuit(), decl(), 1, 2, 3))
        ok = push!(Circuit(), AncillaAlloc(), 3)
        push!(ok, decl(), 1, 2, 3)
        push!(ok, AncillaFree(), 3)
        @test check_ancillas(ok) === nothing
    end

    @testset "random circuits" begin
        rng = Random.MersenneTwister(1234)
        for trial in 1:20
            N = 5
            c = Circuit()
            for _ in 1:4
                k = rand(rng, 2:4)
                qs = Random.randperm(rng, N)[1:k+1]
                push!(c, Control(k, GateX()), qs...)
                push!(c, GateH(), rand(rng, 1:N))
            end
            borrow = rand(rng, Bool)
            m = rand(rng, 1:2)
            basis = CanonicalBasis(borrow=borrow, max_ancillas=m)
            d = decompose(c; basis=basis, wrap=rand(rng, Bool))
            @test check_ancillas(d) === nothing
            @test numqubits(d) <= N + m
            # Flattening again reads the markers and keeps the width.
            f = decompose(d; basis=basis)
            @test check_ancillas(f) === nothing
            @test numqubits(f) == numqubits(d)
            @test _acts_as(f, c, N)
        end
    end
end

# The measured uncompute of an AND (MeasureReset, then a CZ conditioned on the
# bit) has a coherent equivalent: a CZ controlled by the ancilla, then H on it.
# Both return the ancilla to |0⟩ with the same state on the other qubits.
function _coherent(d)
    out = Circuit()
    insts = d._instructions
    i = 1
    while i <= length(insts)
        op = getoperation(insts[i])
        if op isa MeasureReset
            t = getqubit(insts[i], 1)
            cond = insts[i+1]
            @assert getoperation(cond) == IfStatement(GateCZ(), bs"1")
            a, b = getqubits(cond)
            push!(out, Control(2, GateZ()), t, a, b)
            push!(out, GateH(), t)
            i += 2
        else
            op isa AbstractClassical || push!(out, insts[i])
            i += 1
        end
    end
    return out
end

# A C_n(X) on qubits 1:n+1 and one bit, which measuring rules need.
function _cnx_with_bit(n)
    c = push!(Circuit(), Control(n, GateX()), 1:n+1...)
    return push!(c, SetBit0(), 1)
end

@testset "Measured uncompute" begin
    @testset "T counts" begin
        for n in 2:6
            basis = CliffordTBasis(max_ancillas=n - 1, allow_measurement=true)
            d = decompose(_cnx_with_bit(n); basis=basis)
            # n-1 ANDs with 4 T each, none to undo them.
            @test _tcount(d) == 4 * (n - 1)
            @test count(inst -> getoperation(inst) isa MeasureReset, d) == n - 1
            @test check_ancillas(d) === nothing
        end
    end

    @testset "C$(n)X with $m ancillas" for n in 2:4, m in 1:n-1
        c = _cnx_with_bit(n)
        d = decompose(c; basis=CliffordTBasis(max_ancillas=m, allow_measurement=true))
        @test ancillas(d) == collect(n+2:n+1+m)
        # Measurements write one bit, after those of the circuit.
        @test all(inst -> getbits(inst) == (2,), filter(inst -> getoperation(inst) isa MeasureReset, d._instructions))
        @test _acts_as(_coherent(d), push!(Circuit(), Control(n, GateX()), 1:n+1...), n + 1)
    end

    @testset "circuits without bits are refused" begin
        c = push!(Circuit(), GateCCX(), 1, 2, 3)
        @test_throws ArgumentError decompose(c; basis=CliffordTBasis(max_ancillas=1, allow_measurement=true))
        @test decompose(c; basis=CliffordTBasis(allow_measurement=false)) isa Circuit
    end

    @testset "decompose! numbers after the destination" begin
        dest = push!(Circuit(), GateH(), 6)
        push!(dest, Measure(), 6, 2)
        src = push!(Circuit(), Control(4, GateX()), 1:5...)
        push!(src, Measure(), 1, 1)
        decompose!(dest, src; basis=CanonicalBasis(max_ancillas=1, allow_measurement=true))
        @test ancillas(dest) == [7]
        @test all(inst -> getbits(inst) == (3,), filter(inst -> getoperation(inst) isa MeasureReset, dest._instructions))
        @test check_ancillas(dest) === nothing
    end

    @testset "conditional gates stay unitary" begin
        c = push!(Circuit(), IfStatement(Control(3, GateX()), bs"1"), 1:4..., 1)
        d = decompose(c; basis=CliffordTBasis(max_ancillas=2, allow_measurement=true))
        @test !any(inst -> getoperation(inst) isa Union{MeasureReset,Measure}, d)
        @test check_ancillas(d) === nothing
    end

    @testset "wrap" begin
        c = _cnx_with_bit(3)
        basis = CliffordTBasis(max_ancillas=2, allow_measurement=true)
        w = decompose(c; basis=basis, wrap=true)
        @test check_ancillas(w) === nothing
        calls = filter(inst -> getoperation(inst) isa BlockCall, w._instructions)
        @test length(calls) == 1
        @test numancillas(getoperation(calls[1])) == 2
        @test getbits(calls[1]) == (2,)
        f = decompose(w; basis=basis)
        @test _acts_as(_coherent(f), push!(Circuit(), Control(3, GateX()), 1:4...), 4)

        # The same gate twice shares one cached declaration.
        push!(c, Control(3, GateX()), 1:4...)
        w = decompose(c; basis=basis, wrap=true)
        calls = filter(inst -> getoperation(inst) isa BlockCall, w._instructions)
        @test length(calls) == 2
        @test getoperation(calls[1])._decl === getoperation(calls[2])._decl

        # A cache shared with a basis that may not measure does not hand back
        # the measuring declaration.
        cache = MimiqCircuitsBase.WrappedDeclCache()
        collect(eachdecomposed(c; basis=basis, wrap=true, cache=cache))
        u = collect(eachdecomposed(c; basis=CliffordTBasis(max_ancillas=2), wrap=true, cache=cache))
        @test !any(inst -> getoperation(inst) isa BlockCall, u)
    end

    @testset "pauli_based_computation gets no ancillas" begin
        c = push!(Circuit(), GateCCX(), 1, 2, 3)
        push!(c, Measure(), 3, 1)
        pbc = pauli_based_computation(c; basis=CliffordTBasis(max_ancillas=2, allow_measurement=true))
        @test numqubits(pbc) <= 4
    end
end
