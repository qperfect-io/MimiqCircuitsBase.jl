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
    MeasurePauli(pauli)

Pauli product measurement: projective measurement of the ``N``-qubit
observable ``P = P_1 \otimes P_2 \otimes \dots \otimes P_N``, with each
``P_i \in \{I, X, Y, Z\}``.

The instruction targets ``N`` qubits and one classical bit. The state is
projected onto the ``+1`` or ``-1`` eigenspace of ``P`` and the bit records
the outcome: `0` for ``+1``, `1` for ``-1``. Qubits marked `I` are targets of
the instruction but are not measured.

To measure ``-P``, measure ``P`` and flip the bit with [`Not`](@ref).

## Arguments

* `pauli`: a [`PauliString`](@ref), or a string of `I`, `X`, `Y`, `Z`.

Throws an `ArgumentError` if `pauli` is the identity, since there is nothing
to measure.

See also [`PauliString`](@ref), [`RPauli`](@ref), [`MeasureZZ`](@ref),
[`MeasureXX`](@ref), [`MeasureYY`](@ref), [`pauli_based_computation`](@ref).

## Examples

Measure ``X_1 Z_3`` on qubits 1 to 3 and store the outcome in bit 1. Qubit 2
is a target, but is left untouched:

```jldoctest
julia> c = push!(Circuit(), MeasurePauli("XIZ"), 1, 2, 3, 1)
3-qubit, 1-bit circuit with 1 instruction:
└── MP(XIZ) @ q[1:3], c[1]
```

## Decomposition

Each measured qubit is rotated to the Z basis (`H` for `X`, `SDG` then `H`
for `Y`), CX gates collect the parity of the measured qubits on the last one,
that qubit is measured, and the CX gates and rotations are undone:

```jldoctest
julia> decompose_step(MeasurePauli("XZ"))
2-qubit, 1-bit circuit with 5 instructions:
├── H @ q[1]
├── CX @ q[1], q[2]
├── M @ q[2], c[1]
├── CX @ q[1], q[2]
└── H @ q[1]
```

Only `H`, `S`, `SDG`, `CX` and `Measure` appear, so [`QASMBasis`](@ref)
decomposes it. [`StimBasis`](@ref) keeps it, as Stim measures Pauli products
natively (`MPP`), and so does [`CliffordTBasis`](@ref).
"""
struct MeasurePauli{N} <: AbstractMeasurement{N}
    pauli::PauliString{N}

    function MeasurePauli(pauli::PauliString{N}) where {N}
        if isidentity(pauli)
            throw(ArgumentError("Cannot measure the identity Pauli string."))
        end
        new{N}(pauli)
    end
end

MeasurePauli(pauli::Union{Char,String}) = MeasurePauli(PauliString(pauli))

MeasurePauli() = LazyExpr(MeasurePauli, LazyArg())

opname(::Type{<:MeasurePauli}) = "MeasurePauli"

qregsizes(::MeasurePauli{N}) where {N} = (N,)

pstring(m::MeasurePauli) = pstring(m.pauli)

inverse(::MeasurePauli) = error("Cannot invert measurements")

matches(::CanonicalRewrite, ::MeasurePauli) = true

function decompose_step!(builder, ::CanonicalRewrite, m::MeasurePauli, qtargets, ctargets, _)
    active = [(p, q) for (p, q) in zip(pstring(m), qtargets) if p != 'I']
    target = last(active)[2]

    # Keep the decomposed circuit as wide as the instruction.
    max_targ = maximum(qtargets)
    if all(((_, q),) -> q != max_targ, active)
        push!(builder, GateID(), max_targ)
    end

    # H·S† maps Y to Z using only gates that the Stim and QASM bases keep.
    for (p, q) in active
        p == 'Y' && push!(builder, GateSDG(), q)
        p != 'Z' && push!(builder, GateH(), q)
    end
    for (_, q) in active
        q != target && push!(builder, GateCX(), q, target)
    end

    push!(builder, Measure(), target, ctargets[1])

    for (_, q) in Iterators.reverse(active)
        q != target && push!(builder, GateCX(), q, target)
    end
    for (p, q) in Iterators.reverse(active)
        p != 'Z' && push!(builder, GateH(), q)
        p == 'Y' && push!(builder, GateS(), q)
    end

    return builder
end

function Base.show(io::IO, m::MeasurePauli)
    print(io, "MeasurePauli(\"", pstring(m), "\")")
end

function Base.show(io::IO, ::MIME"text/plain", m::MeasurePauli)
    print(io, "MP(", pstring(m), ")")
end
