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

"""
    AbstractOperator{N} <: Operation{N,0,0}

Supertype for all the `N`-qubit operators.

Note that objects of type AbstractOperator do not need to be unitary.

Operators can be used to define Kraus channels (noise) [`AbstractKrausChannel`](@ref),
or to compute expectation values [`ExpectationValue`](@ref). However,
they will return an error if we attempt to directly apply them to states.

See also [`matrix`](@ref), [`isunitary`](@ref).
"""
abstract type AbstractOperator{N} <: Operation{N,0,0} end

# documentation defined in src/abstract.jl
# in this library gate is a shorthand for 
# unitary gate.
isunitary(::Type{T}) where {T<:AbstractOperator} = false

# documentation defined in src/docstrings.jl
inverse(::AbstractOperator) = error("Cannot invert non-unitary operator")

_power(::AbstractOperator, n) = error("Cannot take power of non-unitary operator")

"""
    matrix(operator)

Matrix associated to the given operator.

!!! note
    if the operator is parametric, the matrix elements are wrapped in a
    `Symbolics.Num` object. To manipulate expressions use the `Symbolics`
    package.

## Examples

```jldoctests
julia> matrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107

julia> matrix(GateRX(π/2))
2×2 Matrix{ComplexF64}:
 0.707107+0.0im            0.0-0.707107im
      0.0-0.707107im  0.707107+0.0im
```
"""
function matrix end

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

matrix(g::T) where {T<:AbstractOperator} = matrix(g, Val(numparams(T) != 0))

matrix(g::Instruction{N,0,<:AbstractOperator{N}}) where {N} = matrix(getoperation(g))

"""
    UnexpectedSymbolics(sym, expr)

Error to be thrown when a unexpected symbolics is present in an expression.
"""
struct UnexpectedSymbolics <: Exception
    expr::String
end

function Base.showerror(io::IO, e::UnexpectedSymbolics)
    println(io, "Unexpected symbolic expression $(e.expr). Try to evaluate or define all symbols.")
end

"""
    unwrappedmatrix(operator)

Returns the matrix associated to the specified quantum operator without
the `Symbolics.Num` wrapper.

!!! note
    If any of the gate's parameters is symbolic, an error is thrown.

See also [`matrix`](@ref).

## Examples

```jldoctests; setup=:(import MimiqCircuitsBase.unwrappedmatrix)
julia> unwrappedmatrix(GateRX(π/2))
2×2 Matrix{ComplexF64}:
 0.707107+0.0im            0.0-0.707107im
      0.0-0.707107im  0.707107+0.0im

julia> unwrappedmatrix(GateH())
2×2 Matrix{Float64}:
 0.707107   0.707107
 0.707107  -0.707107
```
"""
function unwrappedmatrix(g::T) where {T<:AbstractOperator}
    if numparams(g) == 0
        return matrix(g)
    end

    # Check the parameters.
    # Assumes that the parameters cannot be complex.
    params = map(getparams(g)) do p
        v = Symbolics.value(p)

        if v isa Number
            return v
        elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:π}}
            return π
        elseif v isa SymbolicUtils.BasicSymbolic{Irrational{:ℯ}}
            return ℯ
        end

        vv = Symbolics.value(Symbolics.substitute(p, Dict()))

        if vv isa Number
            return vv
        end

        throw(UnexpectedSymbolics(string(g)))
    end

    return _matrix(T, params...)
end

"""
    opsquared(op)

Compute ``A^\\dagger A`` for an operator ``A``.
"""
function opsquared(op::AbstractOperator)
    error("opsquared not implemented for $(typeof(op)).")
end

"""
    oprescale(op, a)

Compute ``a * A`` for an operator ``A`` and rescaling factor ``a``.
"""
function rescale(op::AbstractOperator, _)
    error("oprescale not implemented for $(typeof(op)).")
end

"""
Rewrite number in units of π, if number is rational multiple of π.
"""
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

function Base.show(io::IO, ::MIME"text/plain", op::AbstractOperator)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    print(io, opname(op))
    if numparams(op) > 0
        print(io, "(")
        join(io, map(x -> _displaypi(getparam(op, x)), parnames(op)), sep)
        print(io, ")")
    end
end

function Base.show(io::IO, op::AbstractOperator)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    print(io, Base.typename(typeof(op)).name)
    print(io, "(")
    join(io, map(x -> _displaypi(getparam(op, x)), parnames(op)), sep)
    print(io, ")")
end
