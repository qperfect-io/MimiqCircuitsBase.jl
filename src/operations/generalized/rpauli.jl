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
    RPauli(pauli::String, param)

Apply an exponential of a Pauli string rotation gate of the form:

```
\mathrm{e}^{-\imath \frac{\theta}{2} \left(P_1 \otimes P_2 \otimes \dots\right)}
```

Each ``P_i`` is a Pauli operator ``I`` ``X``, ``Y``, or ``Z``.

## Examples

```jldoctests
julia> RPauli("X", π/2)
exp(-i * 1.5707963267948966 * X)

julia> RPauli("ZIZ", 2.0)
exp(-i * 2.0 * ZIZ)

julia> RPauli("ZIZ", 2.0)|>decompose
3-qubit circuit with 3 instructions:
├── CX @ q[1], q[3]
├── RZ(2.0) @ q[3]
└── CX @ q[1], q[3]

julia> c = push!(Circuit(), RPauli("YXI", 2.0), 1, 2, 3)
3-qubit circuit with 1 instructions:
└── exp(-i * 2.0/2 * YXI) @ q[1:3]

julia> push!(c, RPauli("III", π), 1, 2, 3)
3-qubit circuit with 2 instructions:
├── exp(-i * 2.0/2 * YXI) @ q[1:3]
└── identity rotation (noop) @ q[1:3]

julia> push!(c, RPauli("IXY", π), 1, 2, 3)
3-qubit circuit with 3 instructions:
├── exp(-i * 2.0/2 * YXI) @ q[1:3]
├── identity rotation (noop) @ q[1:3]
└── exp(-i * π * IXY) @ q[1:3]
"""
struct RPauli{N} <: AbstractGate{N}
    pauli::PauliString
    θ::Num

    function RPauli(pauli::PauliString{N}, θ) where {N}
        new{N}(pauli, θ)
    end
end

function RPauli(string::String, θ)
    pauli = PauliString(string)
    RPauli(pauli, θ)
end

opname(::Type{<:RPauli}) = "RPauli"

qregsizes(::RPauli{N}) where {N} = (N,)

isidentity(g::RPauli) = isidentity(g.pauli) || iszero(g.θ)

RPauli() = LazyExpr(RPauli, LazyArg(), LazyArg())

RPauli(pauli::String) = LazyExpr(RPauli, pauli, LazyArg())

RPauli(par::Any) = LazyExpr(RPauli, LazyArg(), par)

matches(::CanonicalRewrite, ::RPauli) = true

function decompose_step!(circ, ::CanonicalRewrite, rp::RPauli{N}, qtargets, _, _) where {N}
    s = pstring(rp.pauli)

    if length(s) != length(qtargets)
        throw(ArgumentError("Length of Pauli string and qubit list must match."))
    end

    # Determine active (non-'I') qubits
    active = [(p, q) for (p, q) in zip(s, qtargets) if p != 'I']
    active_qubits = [q for (_, q) in active]

    if isempty(active)
        push!(circ, GateU(0, 0, 0, -rp.θ / 2), maximum(qtargets))
        return circ
    end

    # Be sure the circuit applies to the same number of qubits as the gate
    # TODO: there should be a better way to do this.
    max_targ = maximum(qtargets)
    if maximum(qtargets) ∉ active_qubits
        push!(circ, GateID(), max_targ)
    end

    # Apply basis
    for (p, q) in active
        if p == 'X'
            push!(circ, GateH(), q)
        elseif p == 'Y'
            push!(circ, GateHYZ(), q)
        end
    end

    # Rotation
    push!(circ, GateRNZ(length(active_qubits), rp.θ), active_qubits...)

    # Reverse
    for (p, q) in reverse(active)
        if p == 'X'
            push!(circ, GateH(), q)
        elseif p == 'Y'
            push!(circ, GateHYZ(), q)
        end
    end

    return circ
end

function matrix(g::RPauli)
    if all(p -> p == 'I', pstring(g.pauli))
        θ = try
            unwrapvalue(g.θ)
        catch e
            if e isa UndefinedValue
                return g.θ
            end
            rethrow(e)
        end
        M = 2^numqubits(g)
        return cis(-θ / 2) * Matrix(I, (M, M))
    end

    try
        θ = unwrapvalue(g.θ)
        return exp(-im * θ / 2 * matrix(g.pauli))
    catch e
        if e isa UndefinedValue
            symbols = listsymbols(g.θ)
            println(typeof.(symbols))
            println(symbols)
            decl = GateDecl(:rpauli, tuple(symbols...), decompose(g))
            return Symbolics.simplify.(matrix(decl(symbols...)))
        end
        rethrow(e)
    end
end

unwrappedmatrix(op::RPauli{N}) where {N} = matrix(op)

inverse(g::RPauli) = RPauli(g.pauli, -g.θ)

function Base.show(io::IO, g::RPauli{N}) where {N}
    print(io, "RPauli(\"", g.pauli, "\", ", g.θ, ")")
end

function Base.show(io::IO, ::MIME"text/plain", g::RPauli{N}) where {N}
    print(io, "R(\"", pstring(g.pauli), "\", ", g.θ, ")")
end
