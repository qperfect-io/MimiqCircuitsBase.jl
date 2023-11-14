#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
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
    For allowing simplifications, always prefer rational powers, such as `1//2`
    over floating point ones, such as `0.5`.

!!! warn
    Users should not use directly `Power` but the `power` method, which
    performs already all the simplifications.
    Gates should implement the `_power` method instead.

See also [`power`](@ref), [`Inverse`](@ref) , [`inverse`](@ref).

## Example

```jldoctests
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

```jldoctests
julia> decompose(Power(GateH(), 2))
1-qubit circuit with 2 instructions:
├── H @ q1
└── H @ q1

julia> decompose(Power(GateH(), 1//2))
1-qubit circuit with 1 instructions:
└── H^(1//2) @ q1

julia> decompose(Power(GateX(), 1//2)) # same as decomposing GateSX
1-qubit circuit with 4 instructions:
├── S† @ q1
├── H @ q1
├── S† @ q1
└── GPhase(π/4) @ q1
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
        new{pwr,N,typeof(op)}(op)
    end
end

Power(op::Power{P}, pwr) where {P} = Power(getoperation(op), P * pwr)

_power(op::Power{P}, pwr) where {P} = _power(getoperation(op), P * pwr)

getoperation(op::Power) = op.op

iswrapper(::Type{<:Power}) = true

qregsizes(q::Power) = qregsizes(getoperation(q))

parnames(::Type{Power{P,N,T}}) where {P,N,T} = parnames(T)

getparam(op::Power, name) = getparam(getoperation(op), name)

opname(::Type{<:Power}) = "Power"

"""
    exponent(poweroperation)

Exponent associated with a power operation

## Examples

```jldoctests
julia> MimiqCircuitsBase.exponent(power(GateH(), 2))
2

julia> MimiqCircuitsBase.exponent(GateSX())
1//2
```
"""
exponent(::Power{P}) where {P} = P

@generated _matrix(::Type{Power{P,N,T}}) where {P,N,T} = complex(_matrix(T))^P

_matrix(::Type{Power{P,N,T}}, args...) where {P,N,T} = complex(_matrix(T, args...))^P

function decompose!(circ::Circuit, pwr::Power{P}, qtargets, _) where {P}
    op = getoperation(pwr)
    if exponent(pwr) isa Integer
        for _ in 1:exponent(pwr)
            push!(circ, op, qtargets...)
        end
        return circ
    end

    # try to decompose,
    # if there is only a gate, maybe it is ok
    # if the gates are all diagonal then we can continue
    # otherwise just do nothing and push the same thing
    cop = decompose!(Circuit(), op, qtargets, ())

    if length(cop) == 1
        push!(circ, power(getoperation(cop[1]), P), getqubits(cop[1])...)
        return circ
    end

    push!(circ, pwr, qtargets...)
    return circ
end

function Base.show(io::IO, op::Power)
    exp = exponent(op)
    if (exp isa Integer || exp isa AbstractFloat) && exp >= 0
        print(io, op.op, '^', exp)
    else
        print(io, op.op, "^(", exp, ')')
    end
end
