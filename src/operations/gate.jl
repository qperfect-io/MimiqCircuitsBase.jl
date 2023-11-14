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
    AbstractGate{N} <: Operation{N,0}

Supertype for all the `N`-qubit unitary gates.

See also [`hilbertspacedim`](@ref), [`inverse`](@ref), [`isunitary`](@ref),
[`matrix`](@ref), [`numqubits`](@ref), [`opname`](@ref)
"""
abstract type AbstractGate{N} <: Operation{N,0} end

# documentation defined in src/abstract.jl
# in this library gate is a shorthand for 
# unitary gate.
isunitary(::Type{T}) where {T<:AbstractGate} = true

# documentation defined in src/docstrings.jl
# by default gates are wrapped in the Inverse operation
inverse(op::AbstractGate) = Inverse(op)


_power(op::AbstractGate, n) = Power(op, n)

"""
    matrix(gate)

Matrix associated to the given gate.

!!! note
    if the gate is parametric, the matrix elements are is wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

## Examples

Matrix of a simple gate
```jldoctests
julia> matrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107
```

```jldoctests
julia> matrix(GateRX(π/2))
2×2 Matrix{ComplexF64}:
    0.707107+5.55112e-17im       0.0-0.707107im
 1.11022e-16-0.707107im     0.707107+5.55112e-17im

julia> matrix(GateCX())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  0.0  1.0
 0.0  0.0  1.0  0.0

```
"""
function matrix end

matrix(g::Instruction{N,0,<:AbstractGate{N}}) where {N} = matrix(getoperation(g))


@generated matrix(g::T, ::Val{false}) where {T} = _matrix(T)

function matrix(g::T, ::Val{true}) where {T}
    params = map(getparams(g)) do p
        v = Symbolics.value(p)
        v isa Number && return v
        v isa SymbolicUtils.BasicSymbolic{Irrational{:π}} && return π
        v isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}} && return ℯ
        return p
    end
    return _matrix(T, params...)
end

matrix(g::T) where {T<:AbstractGate} = matrix(g, Val(numparams(T) != 0))

"""
    UndefinedParameterError(name, gatename)

The parameters of the gate are undefined.
`name` is the name of the parameter, `gatename` the one of the gate.
"""
struct UndefinedParameterError <: Exception
    name::Symbol
    gatename::String
end

function showerror(io::IO, e::UndefinedParameterError)
    print(io, "Undefined parameter $(e.name) in gate $(e.gatename)")
end

"""
    unwrappedmatrix(gate)

Returns the matrix associated to the specified quantum gate without
the `Symbolics.Num` wrapper.

!!! note
    If any of the gate's parameters is symbolic, an error is thrown.

See also [`matrix`](@ref).

## Examples

```jldoctests; setup=:(import MimiqCircuitsBase.unwrappedmatrix)
julia> unwrappedmatrix(GateRX(π/2))
2×2 Matrix{ComplexF64}:
    0.707107+5.55112e-17im       0.0-0.707107im
 1.11022e-16-0.707107im     0.707107+5.55112e-17im

julia> unwrappedmatrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107
```
"""
function unwrappedmatrix(g::T) where {T<:AbstractGate}
    if numparams(g) == 0
        return matrix(g)
    end

    # Check the parameters.
    # Assumes that the parameters cannot be complex.
    params = []

    for name in parnames(g)
        v = Symbolics.value(getparam(g, name))
        if v isa Number
            push!(params, v)
        elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:π}}
            push!(params, π)
        elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}}
            push!(params, ℯ)
        else
            throw(UndefinedParameterError(name, opname(g)))
        end
    end
    return _matrix(T, params...)
end

function _displaypi(num::Num)

    v = Symbolics.value(num)

    if v isa Float64
        div = v / π
        divint = round(Int, div)
        divrational = rationalize(div)

        if div == divint
            return string(divint) * "π"
        elseif isapprox(divrational, div; rtol=eps(div)) && (divrational.den < 10 || divrational.num == 1)
            numstring = divrational.num == 1 ? "" : string(divrational.num)
            return numstring * "π/" * string(divrational.den)
        else
            return string(v)
        end
    end

    return string(v)
end

_displaypi(num) = num

function Base.show(io::IO, gate::AbstractGate)
    compact = get(io, :compact, false)
    print(io, opname(gate))
    if numparams(gate) > 0
        print(io, "(")
        join(io, map(x -> _displaypi(getproperty(gate, x)), parnames(gate)), compact ? "," : ", ")
        print(io, ")")
    end
end

