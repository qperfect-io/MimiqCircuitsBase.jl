#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2024 QPerfect. All Rights Reserved.
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
    PauliString(paulistr)

``N``-qubit tensor product of Pauli operators.

The PauliString gate can represent any ``N``-qubit tensor product of Pauli
operators of the form

```math
P_1 \otimes P_2 \otimes P_3 \otimes \ldots \otimes P_N,
```

where each ``P_i \in \{ I, X, Y, Z \}`` is a Pauli operator, including the
identity.

See also [`GateID`](@ref), [`GateX`](@ref), [`GateY`](@ref), [`GateZ`](@ref).

## Arguments

* `paulistr`: string of length ``N`` where each character is either
  `"I"`, `"X"`, `"Y"`, or `"Z"`. The number of qubits is equal to ``N``.

## Examples

PauliStrings of any length are supported.

```jldoctests
julia> c = push!(Circuit(), PauliString("XX"), 1, 2)
2-qubit circuit with 1 instructions:
└── XX @ q[1:2]

julia> push!(c, PauliString("IXYZZYXI"), 1, 2, 3, 4, 5, 6, 7, 8)
8-qubit circuit with 2 instructions:
├── XX @ q[1:2]
└── IXYZZYXI @ q[1:8]
```

## Decomposition

Decomposes into one-qubit Pauli gates.

```jldoctests
julia> decompose(PauliString("XIYZZ"))
5-qubit circuit with 5 instructions:
├── X @ q[1]
├── ID @ q[2]
├── Y @ q[3]
├── Z @ q[4]
└── Z @ q[5]
```
"""
struct PauliString{N} <: AbstractGate{N}
    pauli::String

    function PauliString(pauli::Union{Char,String})
        N = length(pauli)

        if N < 1
            throw(ArgumentError("Pauli string cannot be empty."))
        end

        if any(x -> x != 'X' && x != 'Y' && x != 'Z' && x != 'I', pauli)
            throw(ArgumentError("Pauli string can only contain I, X, Y, or Z."))
        end

        new{N}(string(pauli))
    end
end

pstring(g::PauliString) = g.pauli

PauliString() = LazyExpr(PauliString, LazyArg())

opname(::Type{<:PauliString}) = "PauliString"

qregsizes(::PauliString{N}) where {N} = (N,)

inverse(g::PauliString) = g

function convertpauli(x::Char)::AbstractGate
    if x == 'X'
        return GateX()
    elseif x == 'Z'
        return GateZ()
    elseif x == 'Y'
        return GateY()
    elseif x == 'I'
        return GateID()
    end
    error(lazy"Not a valid pauli character '$x'")
end

convertpauli(::GateID) = 'I'
convertpauli(::GateX) = 'X'
convertpauli(::GateY) = 'Y'
convertpauli(::GateZ) = 'Z'

function _matrix(::Type{<:PauliString}, pauli::String)
    mapreduce(kron, pauli) do p
        return matrix(convertpauli(p))
    end
end

unwrappedmatrix(op::PauliString) = matrix(op)

isidentity(g::PauliString) = all(p -> p == 'I', pstring(g))

function _power(g::PauliString, pwr)
    if pwr % 2 == 0
        # NOTE: consider returning parallel(n, GateID())
        return PauliString('I'^length(pstring(g)))
    elseif pwr % 1 == 0
        return g
    else
        throw(ArgumentError("Pauli strings can only be elevated to an integer power."))
    end
end

function decompose!(circ::Circuit, g::PauliString{N}, qreg, _, _) where {N}
    for (p, q) in zip(pstring(g), qreg)
        push!(circ, convertpauli(p), q)
    end
    return circ
end

function Base.show(io::IO, g::PauliString{N}) where {N}
    print(io, "pauli\"", pstring(g), "\"")
end

function Base.show(io::IO, ::MIME"text/plain", g::PauliString{N}) where {N}
    join(io, pstring(g), "")
end


"""
    macro pauli_str(s)

`pauli""` literal for creating a `PauliString` gate.

## Examples

```jldoctests
julia> pauli"XYYXZ"
XYYXZ

```

"""
macro pauli_str(s)
    return :(PauliString($s))
end
