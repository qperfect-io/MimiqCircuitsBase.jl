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

@doc raw"""
    pauli_based_computation(c::Circuit; basis=CliffordTBasis(), magic_states=false)

Rewrite a circuit in Pauli-based computation form: a sequence of ``\pi/8``
Pauli product rotations ([`RPauli`](@ref) with angle ``\pm\pi/4``) and Pauli
product measurements ([`MeasurePauli`](@ref)), with no Clifford gates left.

The circuit is first decomposed with `basis`, which must produce Clifford+T
gates, the measurements and resets listed below, and the conditional
operations described below. Those measurements, resets and conditional Pauli
products are kept whole, whatever `basis` does with them. Each Clifford ``C``
is then moved past every later T gate and measurement, conjugating them: a T
gate on qubit ``q`` becomes the rotation
``\exp(-i \frac{\pi}{8} C^\dagger Z_q C)``, and a measurement of ``Z_q``
becomes a measurement of ``C^\dagger Z_q C``. When the conjugated observable
has a minus sign, the rotation angle is negated, or the measured bit is
flipped with [`Not`](@ref).

The Cliffords left after the last measurement do not change any outcome and
are dropped. The result therefore reproduces the measurement statistics of
`c`, not its final quantum state, and each rotation is exact up to a global
phase. Classical operations and annotations are kept in place; barriers and
identity gates are dropped.

## Measurements, resets and conditional operations

- [`Measure`](@ref), [`MeasureX`](@ref), [`MeasureY`](@ref),
  [`MeasureXX`](@ref), [`MeasureYY`](@ref), [`MeasureZZ`](@ref) and
  [`MeasurePauli`](@ref) measure a Pauli product ``P`` and become a
  `MeasurePauli` of ``C^\dagger P C``.
- A reset in the Z, X or Y basis ([`Reset`](@ref), [`ResetX`](@ref),
  [`ResetY`](@ref)) measures ``Z``, ``X`` or ``Y`` into a new bit, then
  applies, if the outcome is 1, the Pauli that maps the ``-1`` eigenstate to
  the ``+1`` one: ``X`` for the Z and Y bases, ``Z`` for the X basis. The
  measure-and-reset operations ([`MeasureReset`](@ref),
  [`MeasureResetX`](@ref), [`MeasureResetY`](@ref)) do the same with the bit
  they are given.
- An [`IfStatement`](@ref) whose body is made only of Pauli operators applies
  one Pauli product ``P`` when its condition holds. The body can be `GateX`,
  `GateY`, `GateZ`, `GateID`, a [`PauliString`](@ref), or a
  [`Block`](@ref), [`Parallel`](@ref), [`Repeat`](@ref) or [`GateCall`](@ref)
  holding only such operations, at any depth. It becomes one `IfStatement` of
  the `PauliString` ``C^\dagger P C`` with the same condition. The phase of
  ``P`` is dropped, as it only multiplies one classical branch.
- A conditional T or T† gate becomes a conditional `RPauli` rotation with the
  same condition.

Any other conditional operation is refused. After a conditional Clifford gate,
the accumulated Clifford would depend on the condition bits, so the later
rotations and measurements could not be computed before the circuit runs.

## Magic-state injection

With `magic_states=true` the rotations are removed as well. Each ``\pi/8``
rotation on ``P`` consumes a magic state ``T\ket{+}``, prepared with
[`PrepareStateT`](@ref) on one ancilla qubit that is reused for every rotation:

1. `MeasurePauli` of ``P \otimes Z`` on the data qubits and the ancilla, with
   outcome ``m_1``.
2. `MeasurePauli` of ``X`` on the ancilla if ``m_1 = 0``, of ``Y`` if
   ``m_1 = 1`` (swapped for a negative angle), with outcome ``m_2``. The choice
   is made by two [`IfStatement`](@ref)s.

When ``m_2 = 1`` the rotation is applied together with a Pauli byproduct
``P``. Byproducts are not corrected with gates. Instead, their product ``F``
is tracked in classical bits, the Pauli frame: one bit for the X part and one
for the Z part of ``F`` on each data qubit. When ``m_2 = 1``, [`Xor`](@ref)
operations multiply the frame by ``P``. Each later ``m_1`` or measurement outcome
whose Pauli anticommutes with ``F`` is flipped in place, again with `Xor`, so
the bits hold the outcomes of the ideal circuit.

A conditional Pauli, including the correction of a reset, is not applied
either: it multiplies the frame when its condition holds, with the same `Xor`
operations. A condition other than a single bit equal to 1 is first evaluated
into one extra bit with [`SetBit1`](@ref) and 3-bit [`And`](@ref) operations;
each condition bit compared with 0 is flipped with [`Not`](@ref) while it is
read and flipped back right after. A conditional T or T† gate is refused,
since a magic state cannot be injected conditionally.

Every classical operation added is therefore a 3-bit `Xor` or `And`, a `Not`
or a `SetBit1`, whatever the size of the circuit. The result contains only
Pauli product measurements, magic-state preparations and classical logic.

## Bit layout

With ``n_b`` the number of bits of the decomposed circuit and ``r`` its number
of resets, the ``j``-th reset writes its outcome to bit ``n_b + j``. With
magic states, let ``n'_b = n_b + r``, ``n`` be the number of qubits and ``t``
the number of T and T† gates of the decomposed circuit. The ancilla is qubit
``n + 1``. The ``k``-th rotation writes ``m_1`` to bit ``n'_b + 2k - 1`` and
``m_2`` to bit ``n'_b + 2k``. The frame bits of qubit ``q`` follow: the X
part at bit ``n'_b + 2t + q`` and the Z part at bit ``n'_b + 2t + n + q``.
The condition of a conditional Pauli, when it needs its own bit, goes to bit
``n'_b + 2t + 2n + 1``.

## Errors

Throws a `DecompositionError` if `basis` cannot decompose an operation, such
as a noise channel. Throws an `ArgumentError` if the decomposed circuit
contains anything other than Clifford+T gates, the measurements and resets
listed above, the conditional operations listed above, classical operations
and annotations: for example a non-Clifford gate, a conditional Clifford gate
or a conditional measurement. With `magic_states=true`, a conditional T or T†
gate also throws an `ArgumentError`.

## Examples

Prepare a Bell pair, apply a T gate to qubit 2 and measure both qubits:

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, GateCX(), 1, 2);

julia> push!(c, GateT(), 2);

julia> push!(c, Measure(), 1:2, 1:2);

julia> pauli_based_computation(c)
2-qubit, 2-bit circuit with 3 instructions:
├── R("XZ", π / 4) @ q[1:2]
├── MP(X) @ q[1], c[1]
└── MP(XZ) @ q[1:2], c[2]
```

The Clifford before the T gate is ``C = \mathrm{CX}_{12} H_1``, so the T gate
becomes a ``\pi/8`` rotation on ``C^\dagger Z_2 C = X_1 Z_2``. The two
measurements of ``Z_1`` and ``Z_2`` become measurements of ``X_1`` and
``X_1 Z_2``, and write to the same bits as before.

With magic states, the rotation becomes an injection on the ancilla qubit 3,
whose outcomes ``m_1`` and ``m_2`` go to the new bits 3 and 4:

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, GateCX(), 1, 2);

julia> push!(c, GateT(), 2);

julia> push!(c, Measure(), 1:2, 1:2);

julia> pauli_based_computation(c; magic_states=true)
3-qubit, 8-bit circuit with 8 instructions:
├── PrepareStateT @ q[3]
├── MP(XZZ) @ q[1:3], c[3]
├── IF(c==0) MP(X) @ q[3], c[4], condition[3]
├── IF(c==1) MP(Y) @ q[3], c[4], condition[3]
├── c[5] ⊻= c[4]
├── c[8] ⊻= c[4]
├── MP(X) @ q[1], c[1]
└── MP(XZ) @ q[1:2], c[2]
```

The ancilla is measured in X or Y depending on ``m_1`` (bit 3). The byproduct
``X_1 Z_2`` goes into the frame: bit 5 holds its X part on qubit 1 and bit 8
its Z part on qubit 2. The final measurements commute with it, so their bits
are not corrected.

A conditional Pauli and a reset. The Hadamard gate before the conditional
``Z_2`` turns it into a conditional ``X_2``, and the reset of qubit 1 after its
Hadamard gate measures ``X_1`` into the new bit 4, then applies ``Z_1`` if the
outcome is 1:

```jldoctest
julia> c = push!(Circuit(), GateH(), 1);

julia> push!(c, Measure(), 1, 1);

julia> push!(c, GateH(), 2);

julia> push!(c, IfStatement(GateZ(), bs"1"), 2, 1);

julia> push!(c, Reset(), 1);

julia> push!(c, Measure(), 1:2, 2:3);

julia> pauli_based_computation(c)
2-qubit, 4-bit circuit with 6 instructions:
├── MP(X) @ q[1], c[1]
├── IF(c==1) X @ q[2], condition[1]
├── MP(X) @ q[1], c[4]
├── IF(c==1) Z @ q[1], condition[4]
├── MP(X) @ q[1], c[2]
└── MP(X) @ q[2], c[3]
```

## References

- D. Litinski, "A Game of Surface Codes: Large-Scale Quantum Computing with
  Lattice Surgery", Quantum 3, 128 (2019).
- S. Bravyi, G. Smith, J. A. Smolin, "Trading Classical and Quantum
  Computational Resources", Phys. Rev. X 6, 021043 (2016).

See also [`MeasurePauli`](@ref), [`PrepareStateT`](@ref), [`RPauli`](@ref),
[`CliffordTBasis`](@ref).
"""
function pauli_based_computation(
    c::Circuit;
    basis::DecompositionBasis=CliffordTBasis(),
    magic_states::Bool=false,
)
    c = decompose(c; basis=_PBCBasis(basis))
    n = numqubits(c)

    # Each reset measures into its own new bit, after the bits of the circuit.
    nb = numbits(c)
    resetbit = nb
    nb += count(inst -> getoperation(inst) isa _PBCReset, c)

    # Magic-state injection: one reused ancilla after the data qubits. Rotation
    # rot writes its outcomes to bits nb+2rot-1 and nb+2rot, and the Pauli frame
    # follows the last rotation's bits: fx[q] at nb+2t+q and fz[q] at nb+2t+n+q.
    # The bit after the frame holds the condition of a conditional Pauli.
    t = count(inst -> getoperation(inst) isa Union{GateT,GateTDG}, c)
    anc = n + 1
    frame = _PauliFrame(nb + 2t, n)
    condbit = nb + 2t + 2n + 1
    rot = 0

    # Heisenberg tableau of the Cliffords seen so far, C: tx[q] = C†XqC, tz[q] = C†ZqC.
    tx = [_pauli_generator(n, q, true) for q in 1:n]
    tz = [_pauli_generator(n, q, false) for q in 1:n]
    cache = Dict{Tuple{AbstractGate,Int,Char},Tuple{Int,Vector{Tuple{Int,Char}}}}()
    out = Circuit()

    # A Pauli P applied when the bits cbits match pattern. Moving it before the
    # Cliffords turns it into Q = C†PC, whose sign does not matter.
    function conditional_pauli!(Q, cbits, pattern)
        x, z, _ = Q
        any(x) || any(z) || return

        if !magic_states
            qs, P, _ = _pauli_string(Q)
            push!(out, IfStatement(PauliString(P), pattern), qs..., cbits...)
            return
        end

        # With magic states, Q goes into the Pauli frame, multiplied in when the
        # condition holds. A condition other than a single bit equal to 1 is
        # first reduced to condbit with 3-bit And; a bit expected to be 0 is
        # flipped just for the time it is read.
        if length(cbits) == 1 && pattern[1]
            _frame_update!(out, frame, Q, cbits[1])
            return
        end
        push!(out, SetBit1(), condbit)
        for (b, v) in zip(cbits, pattern)
            v || push!(out, Not(), b)
            push!(out, And(), condbit, condbit, b)
            v || push!(out, Not(), b)
        end
        _frame_update!(out, frame, Q, condbit)
    end

    for inst in c
        op = getoperation(inst)

        if (op isa GateT || op isa GateTDG) && magic_states
            rot += 1
            pauli = tz[getqubit(inst, 1)]
            qs, P, sign = _pauli_string(pauli)
            m1, m2 = nb + 2rot - 1, nb + 2rot

            push!(out, PrepareStateT(), anc)
            push!(out, MeasurePauli(P * "Z"), qs..., anc, m1)

            # A byproduct that anticommutes with P flips m1.
            _frame_correct!(out, frame, pauli, m1)

            # The X measurement completes exp(-iπ/8·P) when the corrected m1 is 0
            # and the Y measurement when it is 1; the opposite rotation, from a
            # T† or a negative sign, swaps the two.
            positive = (op isa GateT) == (sign > 0)
            push!(out, IfStatement(MeasurePauli("X"), BitString(positive ? "0" : "1")), anc, m2, m1)
            push!(out, IfStatement(MeasurePauli("Y"), BitString(positive ? "1" : "0")), anc, m2, m1)

            # Outcome 1 leaves the Pauli byproduct P on the data.
            _frame_update!(out, frame, pauli, m2)

        elseif op isa GateT || op isa GateTDG
            qs, P, sign = _pauli_string(tz[getqubit(inst, 1)])
            θ = (op isa GateT) == (sign > 0) ? Num(π) / 4 : -Num(π) / 4
            push!(out, RPauli(P, θ), qs...)

        elseif (m = _pauli_measurement(op)) !== nothing
            # A reset measures into a new bit, a measure-and-reset into its own
            # bit; both then apply, if the outcome is 1, the Pauli that maps the
            # -1 eigenstate back to the +1 one.
            observable, correction = m
            qs = getqubits(inst)
            b = op isa _PBCReset ? (resetbit += 1) : getbit(inst, 1)
            pauli = _through_tableau(1, observable, qs, tx, tz, n)
            mqs, P, sign = _pauli_string(pauli)
            push!(out, MeasurePauli(P), mqs..., b)
            _frame_correct!(out, frame, pauli, b)
            sign < 0 && push!(out, Not(), b)
            if !isnothing(correction)
                Q = _through_tableau(1, ((1, correction),), qs, tx, tz, n)
                conditional_pauli!(Q, (b,), bs"1")
            end

        elseif op isa GateID || op isa Barrier
            continue

        elseif op isa AbstractGate
            # Appending G to C gives (GC)†P(GC) = C†(G†PG)C: map the local image
            # G†PG through the current tableau. Reading the image of every
            # generator also checks that G is a Clifford.
            qs = collect(getqubits(inst))
            k = length(qs)
            images = map(Iterators.product(1:k, ('X', 'Z'))) do (i, p)
                s, img = get!(() -> _clifford_conjugate(op, i, p), cache, (op, i, p))
                _through_tableau(s, img, qs, tx, tz, n)
            end
            for i in 1:k
                tx[qs[i]] = images[i, 1]
                tz[qs[i]] = images[i, 2]
            end

        elseif op isa AbstractClassical || op isa AbstractAnnotation
            push!(out, inst)

        elseif op isa IfStatement
            body = getoperation(op)
            pattern = getbitstring(op)
            cbits = getbits(inst)[numbits(body)+1:end]
            local_pauli = _as_pauli(body)

            if !isnothing(local_pauli)
                Q = _through_tableau(1, _pauli_pairs(local_pauli...), getqubits(inst), tx, tz, n)
                conditional_pauli!(Q, cbits, pattern)

            elseif (body isa GateT || body isa GateTDG) && !magic_states
                qs, P, sign = _pauli_string(tz[getqubit(inst, 1)])
                θ = (body isa GateT) == (sign > 0) ? Num(π) / 4 : -Num(π) / 4
                push!(out, IfStatement(RPauli(P, θ), pattern), qs..., cbits...)

            elseif body isa GateT || body isa GateTDG
                throw(ArgumentError("Pauli-based computation with magic_states=true does not support a classically controlled $(opname(body)) gate: a magic state cannot be injected conditionally. Use magic_states=false to keep it as a conditional rotation."))

            elseif body isa AbstractGate
                throw(ArgumentError("Pauli-based computation does not support a classically controlled $(opname(body)) gate: the Clifford accumulated after it would depend on the condition bits, so the later rotations and measurements cannot be computed statically. Only conditional Pauli operators and conditional T or T† gates are supported."))

            else
                throw(ArgumentError("Pauli-based computation does not support a classically controlled $(opname(body)). Only conditional Pauli operators and conditional T or T† gates are supported."))
            end

        else
            throw(ArgumentError("Pauli-based computation does not support $(opname(op))."))
        end
    end

    return out
end

# Decomposes with `basis`, but keeps whole the operations that the pass handles
# directly: Pauli measurements and resets, which need no expansion into
# Clifford gates, and conditional Pauli products, which `basis` could split
# into several conditional gates.
struct _PBCBasis{B<:DecompositionBasis} <: DecompositionBasis
    basis::B
end

isterminal(b::_PBCBasis, op::Operation) = !isnothing(_pauli_measurement(op)) || isterminal(b.basis, op)
isterminal(b::_PBCBasis, op::IfStatement) = !isnothing(_as_pauli(getoperation(op))) || isterminal(b.basis, op)
decompose!(builder, b::_PBCBasis, op::Operation, qt, ct, zt) = decompose!(builder, b.basis, op, qt, ct, zt)

const _PBCReset = Union{Reset,ResetX,ResetY}

# The Pauli measured by a measurement or a reset, as (qubit, letter) pairs over
# its qubits, and the letter of the Pauli that maps the -1 eigenstate to the +1
# one, applied after a reset when the outcome is 1 (nothing for a measurement).
_pauli_measurement(::Operation) = nothing
_pauli_measurement(::Measure) = (((1, 'Z'),), nothing)
_pauli_measurement(::MeasureX) = (((1, 'X'),), nothing)
_pauli_measurement(::MeasureY) = (((1, 'Y'),), nothing)
_pauli_measurement(::MeasureXX) = (((1, 'X'), (2, 'X')), nothing)
_pauli_measurement(::MeasureYY) = (((1, 'Y'), (2, 'Y')), nothing)
_pauli_measurement(::MeasureZZ) = (((1, 'Z'), (2, 'Z')), nothing)
_pauli_measurement(m::MeasurePauli) = (Tuple((i, p) for (i, p) in enumerate(pstring(m)) if p != 'I'), nothing)
_pauli_measurement(::Union{Reset,MeasureReset}) = (((1, 'Z'),), 'X')
_pauli_measurement(::Union{ResetX,MeasureResetX}) = (((1, 'X'),), 'Z')
_pauli_measurement(::Union{ResetY,MeasureResetY}) = (((1, 'Y'),), 'X')

# The Pauli product applied by an operation made only of Pauli operators, as its
# X and Z bit sets over the operation's qubits, or nothing for any other
# operation. The phase is dropped.
_as_pauli(::Operation) = nothing
_as_pauli(::GateID) = (falses(1), falses(1))
_as_pauli(::GateX) = (trues(1), falses(1))
_as_pauli(::GateY) = (trues(1), trues(1))
_as_pauli(::GateZ) = (falses(1), trues(1))
_as_pauli(g::PauliString) = (BitVector([p in "XY" for p in pstring(g)]), BitVector([p in "YZ" for p in pstring(g)]))

function _as_pauli(g::Parallel)
    p = _as_pauli(getoperation(g))
    isnothing(p) && return nothing
    return repeat(p[1], numrepeats(g)), repeat(p[2], numrepeats(g))
end

function _as_pauli(g::Repeat)
    p = _as_pauli(getoperation(g))
    isnothing(p) && return nothing
    return isodd(numrepeats(g)) ? p : (falses(length(p[1])), falses(length(p[2])))
end

_as_pauli(b::Block) = numbits(b) == 0 && numzvars(b) == 0 ? _as_pauli(b._instructions, numqubits(b)) : nothing
_as_pauli(g::GateCall) = _as_pauli(g._decl._instructions, numqubits(g))

function _as_pauli(insts::AbstractVector{<:Instruction}, k)
    x, z = falses(k), falses(k)
    for inst in insts
        p = _as_pauli(getoperation(inst))
        isnothing(p) && return nothing
        qs = collect(getqubits(inst))
        x[qs] .⊻= p[1]
        z[qs] .⊻= p[2]
    end
    return x, z
end

# The non-identity (qubit, letter) pairs of the Pauli with bit sets x and z.
_pauli_pairs(x, z) = [(q, x[q] && z[q] ? 'Y' : x[q] ? 'X' : 'Z') for q in findall(x .| z)]

# Pauli frame of the injection: the product of the byproducts left so far,
# stored as its X part in bits fx[q] = offset+q and Z part in fz[q] = offset+n+q.
# Every update and correction is a 3-bit Xor, so the arity of the operations
# emitted does not grow with the circuit. `livex` and `livez` mark the bits ever
# written; the others are known to be 0 and are skipped.
struct _PauliFrame
    offset::Int
    n::Int
    livex::BitVector
    livez::BitVector
end

_PauliFrame(offset, n) = _PauliFrame(offset, n, falses(n), falses(n))

# A measurement of `pauli` flips when the frame anticommutes with it, that is
# for every qubit where the X part of `pauli` meets fz or its Z part meets fx.
function _frame_correct!(out, f::_PauliFrame, pauli, bit)
    x, z, _ = pauli
    for q in 1:f.n
        x[q] && f.livez[q] && push!(out, Xor(), bit, bit, f.offset + f.n + q)
        z[q] && f.livex[q] && push!(out, Xor(), bit, bit, f.offset + q)
    end
end

# Multiplies the frame by `pauli` when `bit` is 1.
function _frame_update!(out, f::_PauliFrame, pauli, bit)
    x, z, _ = pauli
    for q in 1:f.n
        if x[q]
            push!(out, Xor(), f.offset + q, f.offset + q, bit)
            f.livex[q] = true
        end
        if z[q]
            push!(out, Xor(), f.offset + f.n + q, f.offset + f.n + q, bit)
            f.livez[q] = true
        end
    end
end

# A Pauli operator iʳ·X^x·Z^z, with X^x Z^z the qubit-wise product and r mod 4.
const _Pauli = Tuple{BitVector,BitVector,Int}

function _pauli_generator(n, q, isx)
    x, z = falses(n), falses(n)
    (isx ? x : z)[q] = true
    return (x, z, 0)
end

# Moving Z^z₁ past X^x₂ costs (-1)^(z₁·x₂).
function _pauli_mul(a::_Pauli, b::_Pauli)
    (x1, z1, r1), (x2, z2, r2) = a, b
    return (x1 .⊻ x2, z1 .⊻ z2, mod(r1 + r2 + 2 * count(z1 .& x2), 4))
end

# s·img rewritten through the tableau, with img a Pauli given as (i, letter)
# pairs acting on the qubits qs[i].
function _through_tableau(s, img, qs, tx, tz, n)
    acc = (falses(n), falses(n), s > 0 ? 0 : 2)
    for (i, ch) in img
        q = qs[i]
        if ch == 'X'
            acc = _pauli_mul(acc, tx[q])
        elseif ch == 'Z'
            acc = _pauli_mul(acc, tz[q])
        elseif ch == 'Y'
            # Y = i·X·Z
            x, z, r = _pauli_mul(_pauli_mul(acc, tx[q]), tz[q])
            acc = (x, z, mod(r + 1, 4))
        end
    end
    return acc
end

# The support, the letters on it and the ±1 sign of a Hermitian Pauli, using
# X·Z = -i·Y.
function _pauli_string((x, z, r)::_Pauli)
    qs = findall(x .| z)
    P = String([x[q] && z[q] ? 'Y' : x[q] ? 'X' : 'Z' for q in qs])
    r = mod(r - count(x .& z), 4)
    return qs, P, r == 0 ? 1 : -1
end

# C†PC for a k-qubit Clifford C and the generator P = X or Z on its qubit i,
# read off the Pauli basis. The image is returned as a sign and (qubit, letter)
# pairs, qubits counted within the gate.
function _clifford_conjugate(g::AbstractGate, i::Int, p::Char)
    U = ComplexF64.(matrix(g))
    k = numqubits(g)
    R = U' * matrix(PauliString(String([j == i ? p : 'I' for j in 1:k]))) * U

    for chars in Iterators.product(ntuple(_ -> "IXYZ", k)...)
        c = tr(matrix(PauliString(String(collect(chars)))) * R) / 2^k
        if isapprox(abs(real(c)), 1; atol=1e-8)
            return round(Int, real(c)), [(j, ch) for (j, ch) in enumerate(chars) if ch != 'I']
        end
    end

    throw(ArgumentError("Pauli-based computation needs Clifford+T gates, got $(opname(g))."))
end
