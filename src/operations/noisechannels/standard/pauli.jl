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
    PauliNoise(p, paulistrings)

``N`` qubit Pauli noise channel specified by a list of probabilities and Pauli
gates.

A Pauli channel is defined by

```math
\mathcal{E}(\rho) = \sum_k p_k P_k \rho P_k,
```

where ``0 \leq p_k \leq 1`` and ``P_k`` are Pauli string operators,
defined as tensor products of one-qubit Pauli operators (see [`PauliString`](@ref))
The probabilities must fulfill ``\sum_k p_k = 1``.

This channel is a mixed unitary channel, see [`ismixedunitary`](@ref).

See also [`Depolarizing`](@ref), [`PauliX`](@ref), [`PauliY`](@ref), [`PauliZ`](@ref),
which are special cases of PauliNoise.

## Arguments

* `p`: Vector of probabilities that must add up to 1.
* `paulistrings`: Vector of strings, each one of length ``N`` and with each character
  being either `"I"`, `"X"`, `"Y"`, or `"Z"`. The number of qubits is equal to ``N``.

The vectors `p` and `paulistrings` must have the same length.

## Examples

PauliNoise channels can be defined for any number of qubits,
and for any number of Pauli strings.

```jldoctests
julia> push!(Circuit(), PauliNoise([0.8, 0.1, 0.1], ["I","X","Y"]), 1)
1-qubit circuit with 1 instructions:
└── PauliNoise(...) @ q[1]

julia> push!(Circuit(), PauliNoise([0.9, 0.1], ["XY","II"]), 1, 2)
2-qubit circuit with 1 instructions:
└── PauliNoise(...) @ q[1:2]

julia> push!(Circuit(), PauliNoise([0.5, 0.2, 0.2, 0.1], ["IXIX","XYXY","ZZZZ","IXYZ"]), 1, 2, 3, 4)
4-qubit circuit with 1 instructions:
└── PauliNoise(...) @ q[1:4]
```
"""
struct PauliNoise{N} <: AbstractKrausChannel{N}
    p::Vector{Num}
    strings::Vector{PauliString{N}}

    function PauliNoise(p::Vector{<:Number}, strings::Vector{PauliString{N}}) where {N}
        if N < 1
            error("Cannot define a 0-qubit Pauli noise channel")
        end

        if isempty(strings)
            throw(ArgumentError("List of Pauli strings must contain at least one element."))
        end

        if length(p) != length(strings)
            throw(ArgumentError("Lists of probabilities and Paulis must have the same length."))
        end

        if any(x -> !(x isa Symbolics.Num) && (x < 0 || x > 1), p)
            throw(ArgumentError("All probabilities should be between 0 and 1."))
        end

        if all(x -> !(x isa Symbolics.Num), p) && !isapprox(sum(p), 1, rtol=1e-8)
            throw(ArgumentError("List of probabilities should add up to 1."))
        end

        return new{N}(p, strings)
    end
end

function evaluate(pn::PauliNoise, d::Dict=Dict())
    evaluated_p = [Symbolics.substitute(prob, d) for prob in pn.p]
    concrete_values = [Symbolics.value(prob) for prob in evaluated_p]
    
    all_concrete = all(x -> x isa Real, concrete_values)
    
    if all_concrete
        if any(x -> x < 0 || x > 1, concrete_values)
            throw(ArgumentError("All probabilities should be between 0 and 1 after evaluation."))
        end

        if !isapprox(sum(concrete_values), 1, rtol=1e-8)
            throw(ArgumentError("List of probabilities should add up to 1 after evaluation."))
        end
    end

    # Return a new instance with evaluated probabilities, whether concrete or symbolic
    return PauliNoise(evaluated_p, pn.strings)
end



function PauliNoise(p, strings::Vector{<:AbstractString})
    if isempty(strings)
        throw(ArgumentError("List of Pauli strings must contain at least one element."))
    end

    pstrings = PauliString.(strings)

    N = numqubits(pstrings[1])

    if any(pstring -> numqubits(pstring) != N, pstrings)
        throw(ArgumentError("Pauli strings must all be of the same length."))
    end

    return PauliNoise(p, pstrings)
end

opname(::Type{<:PauliNoise}) = "PauliNoise"

probabilities(pauli::PauliNoise) = pauli.p

unitarygates(pauli::PauliNoise) = pauli.strings

ismixedunitary(::Type{T}) where {T<:PauliNoise} = true

function krausoperators(pauli::PauliNoise)
    gates = unitarygates(pauli)
    scales = sqrt.(probabilities(pauli))
    return RescaledGate.(gates, scales)
end

function Base.show(io::IO, ::MIME"text/plain", pauli::PauliNoise)
    if get(io, :compact, false)
        print(io, opname(pauli), "(...)")
        return nothing
    end
    ps = probabilities(pauli)
    gs = unitarygates(pauli)
    print(io, "PauliNoise(")
    print(io, join(["($(p), pauli\"$g\")" for (p, g) in zip(ps, gs)], ", "))
    print(io, ")")
end

@doc raw"""
    PauliX(p)

One-qubit Pauli X noise channel (bit flip error).

This channel is defined by the Kraus operators

```math
E_1 = \sqrt{1-p}\,I, \quad E_2 = \sqrt{p}\,X,
```

where ``0 \leq p \leq 1``.

This channel is a mixed unitary channel, see [`ismixedunitary`](@ref),
and is a special case of [`PauliNoise`](@ref).

`PauliX(p)` is the same as `PauliNoise([1-p,p],["I","X"])`.

## Examples

```jldoctests
julia> push!(Circuit(), PauliX(0.1), 1)
1-qubit circuit with 1 instructions:
└── PauliX(0.1) @ q[1]
```
"""
struct PauliX <: AbstractKrausChannel{1}
    p::Num

    function PauliX(p::Number)
        if !(p isa Symbolics.Num) && (p > 1 || p < 0)
            throw(ArgumentError("Probability should be between 0 and 1."))
        end

        return new(p)
    end
end

function evaluate(gad::PauliX, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(gad.p, d)
    concrete_value =  Symbolics.value(evaluated_p)
  
    if (concrete_value isa Real)
        if concrete_value < 0 || concrete_value > 1
            throw(ArgumentError("Probability p must be between 0 and 1 after evaluation."))
        end
        return PauliZ(concrete_value)
        
    elseif evaluated_p isa Symbolics.Num
        return PauliX(evaluated_p)
    end
end

opname(::Type{<:PauliX}) = "PauliX"

probabilities(pauli::PauliX) = [1 - pauli.p, pauli.p]

unitarygates(::PauliX) = [GateID(), GateX()]

ismixedunitary(::Type{T}) where {T<:PauliX} = true

@doc raw"""
    PauliY(p)

One-qubit Pauli Y noise channel (bit-phase flip error).

This channel is determined by the Kraus operators

```math
E_1 = \\sqrt{1-p}\,I, \\quad E_2 = \sqrt{p}\,Y,
```

where ``0\\leq p \\leq 1``.

This channel is a mixed unitary channel, see [`ismixedunitary`](@ref),
and is a special case of [`PauliNoise`](@ref).

`PauliY(p)` is the same as `PauliNoise([1-p,p],["I","Y"])`.

## Examples

```jldoctests
julia> push!(Circuit(), PauliY(0.1), 1)
1-qubit circuit with 1 instructions:
└── PauliY(0.1) @ q[1]
```
"""
struct PauliY <: AbstractKrausChannel{1}
    p::Num

    function PauliY(p::Number)
        if !(p isa Symbolics.Num) && (p > 1 || p < 0)
            throw(ArgumentError("Probability should be between 0 and 1."))
        end

        return new(p)
    end
end

function evaluate(gad::PauliY, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(gad.p, d)
    concrete_value =  Symbolics.value(evaluated_p)
  
    if (concrete_value isa Real)
        if concrete_value < 0 || concrete_value > 1
            throw(ArgumentError("Probability p must be between 0 and 1 after evaluation."))
        end
        return PauliZ(concrete_value)
        
    elseif evaluated_p isa Symbolics.Num
        return PauliY(evaluated_p)
    end
end
opname(::Type{<:PauliY}) = "PauliY"

probabilities(pauli::PauliY) = [1 - pauli.p, pauli.p]

unitarygates(::PauliY) = [GateID(), GateY()]

ismixedunitary(::Type{T}) where {T<:PauliY} = true

@doc raw"""
    PauliZ(p)

One-qubit Pauli Z noise channel (phase flip error).

This channel is determined by the Kraus operators

```math
E_1 = \sqrt{1-p}\,I, \quad E_2 = \sqrt{p}\,Z,
```

where ``0 \leq p \leq 1``.

This channel is a mixed unitary channel, see [`ismixedunitary`](@ref),
and is a special case of [`PauliNoise`](@ref).

`PauliZ(p)` is the same as `PauliNoise([1-p,p],["I","Z"])`.

## Examples

```jldoctests
julia> push!(Circuit(), PauliZ(0.1), 1)
1-qubit circuit with 1 instructions:
└── PauliZ(0.1) @ q[1]
```
"""
struct PauliZ <: AbstractKrausChannel{1}
    p::Num

    function PauliZ(p::Number)
        if !(p isa Symbolics.Num) && (p > 1 || p < 0)
            throw(ArgumentError("Probability should be between 0 and 1."))
        end

        return new(p)
    end
end

function evaluate(gad::PauliZ, d::Dict=Dict())
    evaluated_p = Symbolics.substitute(gad.p, d)
    concrete_value =  Symbolics.value(evaluated_p)
  
    if (concrete_value isa Real)
        if concrete_value < 0 || concrete_value > 1
            throw(ArgumentError("Probability p must be between 0 and 1 after evaluation."))
        end
        return PauliZ(concrete_value)

    elseif evaluated_p isa Symbolics.Num
        return PauliZ(evaluated_p)
    end
end

opname(::Type{<:PauliZ}) = "PauliZ"

probabilities(pauli::PauliZ) = [1 - pauli.p, pauli.p]

unitarygates(::PauliZ) = [GateID(), GateZ()]

ismixedunitary(::Type{T}) where {T<:PauliZ} = true

