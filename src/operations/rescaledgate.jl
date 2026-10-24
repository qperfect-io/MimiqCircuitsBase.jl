#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 3.0 (the "License");
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
    RescaledGate(gate, m)

The operator ``m \cdot U``: a gate ``U`` whose matrix is multiplied by the
scalar `m`.

The result is in general not unitary, so it is an operator rather than a gate.
It is used to describe the terms of a mixed unitary channel, where each unitary
``U_k`` is applied with probability ``p_k`` and enters as the Kraus operator
``\sqrt{p_k} U_k``.

`m` is a real number between `0` and `1`, or a symbolic expression.
[`getscale`](@ref) returns it and [`getoperation`](@ref) returns the gate.

Throws `ArgumentError` if `m` is numeric and outside ``[0, 1]``.

## Examples

```jldoctest
julia> op = RescaledGate(GateX(), 0.5)
0.5 * X

julia> matrix(op)
2×2 Matrix{Float64}:
 0.0  0.5
 0.5  0.0

julia> getscale(op), getoperation(op)
(0.5, GateX())

julia> rescale(GateH(), 0.25)
0.25 * H
```

See also `MixedUnitary`, `rescale`.
"""
struct RescaledGate{N,T} <: AbstractOperator{N}
    gate::T
    m::Num

    function RescaledGate(gate::T, m) where {N,T<:AbstractGate{N}}
        if !issymbolic(m) && (unwrapvalue(m) < 0 || unwrapvalue(m) > 1)
            throw(ArgumentError("Value of m must be between 0 and 1."))
        end
        new{N,T}(gate, m)
    end
end

opname(::Type{<:RescaledGate}) = "RescaledGate"

iswrapper(::Type{<:RescaledGate}) = true

getoperation(g::RescaledGate) = g.gate

parnames(::Type{<:RescaledGate{N,T}}) where {N,T} = (:m, parnames(T)...)

function getparam(op::RescaledGate, name)
    if name == :m
        return op.m
    end
    getparam(getoperation(op), name)
end

_matrix(::Type{RescaledGate{N,T}}, m, args...) where {N,T} = m .* _matrix(T, args...)

"""
    getscale(op::RescaledGate)

Return the scalar a [`RescaledGate`](@ref) multiplies its gate by.
"""
getscale(op::RescaledGate) = op.m

@doc raw"""
    rescale!(op, scale)

Multiply the operator `op` by `scale` in place and return it.

Only [`Operator`](@ref) and [`LossyOperator`](@ref), which store their matrix, can
be rescaled in place. Every other operation is an immutable value and throws an
`ArgumentError`; use [`rescale`](@ref), which returns a new operation.

## Examples

```jldoctest
julia> op = Operator([1 0; 0 1]);

julia> rescale!(op, 2) === op
true

julia> matrix(op)
2×2 Matrix{ComplexF64}:
 2.0+0.0im  0.0+0.0im
 0.0+0.0im  2.0+0.0im

julia> rescale!(Projector0(), 2)
ERROR: ArgumentError: Cannot rescale P₀ in place. Use `rescale` instead.
[...]
```
"""
function rescale! end

rescale!(op::AbstractOperator, _) =
    throw(ArgumentError("Cannot rescale $(opname(op)) in place. Use `rescale` instead."))

rescale(op::RescaledGate, m) = RescaledGate(getoperation(op), getscale(op) * m)

rescale(op::AbstractGate, m) = RescaledGate(op, m)


evaluate(op::RescaledGate, d::Dict) = RescaledGate(evaluate(getoperation(op), d), evaluate(getscale(op), d))

function Base.show(io::IO, op::RescaledGate)
    sep = get(io, :compact, false) ? ", " : ","
    print(io, opname(op), "(", getoperation(op), sep, _displaynum(io, getscale(op)), ")")
end

function Base.show(io::IO, m::MIME"text/plain", op::RescaledGate)
    mult = get(io, :compact, false) ? "*" : " * "
    print(io, _displaynum(io, getscale(op)), mult)
    show(io, m, getoperation(op))
end
