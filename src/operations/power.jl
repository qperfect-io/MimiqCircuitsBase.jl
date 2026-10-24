#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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

"""
    Power(pow, operation)

Wraps an operation and raises it to the given power.

Some simplifications are already carried out at construction, for example
`Power(pow2, Power(pow1, op))` is simplified as `Power(pow1 * pow2, op)`.

!!! note
    A floating point exponent that is exactly a fraction with denominator at
    most 1000 is stored as that fraction, so `Power(GateX(), 0.5)` is
    `GateSX()`. Other floats, such as `sqrt(2)`, are kept as they are.

!!! warn
    Users should not use directly `Power` but the `power` method, which
    performs already all the simplifications.
    Gates should implement the `_power` method instead.

See also [`power`](@ref), [`Inverse`](@ref) , [`inverse`](@ref).

## Example

```jldoctest
julia> Power(GateZ(), 1//2)
S

julia> Power(GateZ(), 2)
Z^2

julia> Power(GateCH(), 1//2)
CH^(1//2)

julia> Power(GateCX(), 1//2)
CX^(1//2)
```

## Decomposition

In the general case, if a decomposition is not known for a given operation and
power, the `Power` operation is not decomposed.

If the exponent is an integer, then the gate is decomposed by repeating it.

```jldoctest
julia> decompose(Power(GateH(), 2))
1-qubit circuit with 2 instructions:
├── U(π/2,0,π) @ q[1]
└── U(π/2,0,π) @ q[1]

julia> decompose(Power(GateH(), 1//2))
1-qubit circuit with 1 instruction:
└── U(1.0471975511966005,-0.9553166181245096,2.1862760354652835,0.16991845472706107) @ q[1]

julia> decompose(Power(GateX(), 1//2)) # same as decomposing GateSX
1-qubit circuit with 4 instructions:
├── U(0,0,-1π/2) @ q[1]
├── U(π/2,0,π) @ q[1]
├── U(0,0,-1π/2) @ q[1]
└── U(0,0,0,π/4) @ q[1]
```
"""
struct Power{P,N,T<:AbstractGate{N}} <: AbstractGate{N}
    op::T

    function Power{P,N,T}(args...; kwargs...) where {P,N,T<:Operation{N,0}}
        if !(P isa Real) || P < 0
            throw(ArgumentError("Power exponent should be a positive real number."))
        end
        new{P,N,T}(T(args...; kwargs...))
    end

    function Power(op::Operation{N,0}, pwr) where {N}
        if !(pwr isa Real) || pwr < 0
            throw(ArgumentError("Exponent should be a positive real number."))
        end
        new{_normalize_exponent(pwr),N,typeof(op)}(op)
    end
end

Power(op::Power{P}, pwr) where {P} = Power(getoperation(op), P * pwr)

_power(op::Power{P}, pwr) where {P} = _power(getoperation(op), P * pwr)

getoperation(op::Power) = op.op

iswrapper(::Type{<:Power}) = true

qregsizes(q::Power) = qregsizes(getoperation(q))

parnames(::Type{Power{P,N,T}}) where {P,N,T} = parnames(T)

getparam(op::Power, name) = getparam(getoperation(op), name)

function opname(::Type{<:Power{P,N,T}}) where {P,N,T}
    if iswrapper(T) && !isopalias(T)
        op = "($(opname(T)))"
    else
        op = opname(T)
    end

    if (P isa Integer || P isa AbstractFloat) && P >= 0
        return "$(op)^P"
    else
        return "$(op)^($P)"
    end
end

"""
    exponent(poweroperation)

Exponent associated with a power operation

## Examples

```jldoctest
julia> MimiqCircuitsBase.exponent(power(GateH(), 2))
2

julia> MimiqCircuitsBase.exponent(GateSX())
1//2
```
"""
exponent(::Power{P}) where {P} = P

# A matrix power is not type stable (it can come back real or complex), so the
# element type is pinned. With arguments it follows them, as they may be symbolic.
_compute_matrix(::Type{Power{P,N,T}}) where {P,N,T} = Matrix{ComplexF64}(complex(_matrix(T))^P)
_matrix(::Type{Power{P,N,T}}) where {P,N,T} = _cached_matrix(Power{P,N,T})

function _matrix(::Type{Power{P,N,T}}, args...) where {P,N,T}
    m = complex(_matrix(T, args...))
    return Matrix{eltype(m)}(m^P)
end

matches(::CanonicalRewrite, pwr::Power) = true

function decompose_step!(builder, ::CanonicalRewrite, pwr::Power, qtargets, _, _)
    op = getoperation(pwr)

    if exponent(pwr) isa Integer
        for _ in 1:exponent(pwr)
            push!(builder, op, qtargets...)
        end
        return builder
    end

    # (C-U)^p = C-(U^p): the controls pass through the power.
    if op isa Control
        push!(builder, Control(numcontrols(op), power(getoperation(op), exponent(pwr))), qtargets...)
        return builder
    end

    # A single-gate decomposition can be raised to the power directly. Anything
    # longer would need the matrix power of the whole circuit.
    cop = _canonical_pieces(op)

    if length(cop) == 1
        inst = cop[1]
        push!(builder, power(getoperation(inst), exponent(pwr)), [qtargets[q] for q in getqubits(inst)]...)
        return builder
    end

    throw(DecompositionError("Cannot decompose $(opname(pwr)): the decomposition of its base has more than one gate."))
end

function Base.show(io::IO, op::Power)
    exp = exponent(op)
    _print_wrapped_parens(io, getoperation(op))
    if (exp isa Integer || exp isa AbstractFloat) && exp >= 0
        print(io, '^', _displaynum(io, exp))
    else
        print(io, "^(", _displaynum(io, exp), ')')
    end
end

function Base.show(io::IO, m::MIME"text/plain", op::Power)
    exp = exponent(op)
    _show_wrapped_parens(io, m, getoperation(op))
    if (exp isa Integer || exp isa AbstractFloat) && exp >= 0
        print(io, '^', _displaynum(io, exp))
    else
        print(io, "^(", _displaynum(io, exp), ')')
    end
end

function Base.:(==)(p1::Power{P1,N,T1}, p2::Power{P2,N,T2}) where {P1,P2,N,T1,T2}
    exponent(p1) == exponent(p2) || return false
    getoperation(p1) == getoperation(p2) || return false
    return true
end
