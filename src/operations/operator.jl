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

!!! warning
    For an operator without parameters the returned matrix may be shared by
    every call, so mutating it changes the operator's matrix for the whole
    session. Call `copy` on it before modifying it.

## Examples

```jldoctest
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

matrix(g::T, ::Val{false}) where {T} = _matrix(T)

# Per-type cache for the matrices of the wrapper operations (Control, Power,
# Inverse, Parallel, Repeat), so `matrix()` stays allocation-free on the hot
# path. These cannot be @generated: a generator only sees methods that existed
# when it was defined, and the wrapped gate may be defined later in this module
# or in a downstream package.
#
# Copy on write: readers take an atomic snapshot of a table nobody mutates any
# more, so `matrix()` needs no lock and scales across threads. Writers are rare
# (once per type) and pay a full copy. Reading `IdDict` while another task
# inserts is not safe -- `jl_eqtable_put` fills a free slot of the live table in
# place, so a reader can see the key of a half-written entry.
mutable struct _MatrixCache
    @atomic ht::IdDict{Type,Any}
end

const _MATRIX_CACHE = _MatrixCache(IdDict{Type,Any}())
const _MATRIX_CACHE_LOCK = ReentrantLock()

function _compute_matrix end

function _cached_matrix(::Type{T}) where {T}
    # concrete for a concrete T, so the assertion below is free and keeps
    # `_matrix` type stable despite the untyped cache
    R = Base.promote_op(_compute_matrix, Type{T})
    m = get((@atomic :acquire _MATRIX_CACHE.ht), T, nothing)
    m === nothing || return m::R
    return @lock(_MATRIX_CACHE_LOCK, _store_matrix!(T))::R
end

function _store_matrix!(::Type{T}) where {T}
    m = get((@atomic :acquire _MATRIX_CACHE.ht), T, nothing)
    m === nothing || return m
    # built before the snapshot is taken: a wrapper over another wrapper stores
    # the inner matrix during this call, and that entry must not be copied away
    m = _compute_matrix(T)
    ht = copy(@atomic :acquire _MATRIX_CACHE.ht)
    ht[T] = m
    @atomic :release _MATRIX_CACHE.ht = ht
    return m
end

function matrix(g::T, ::Val{true}) where {T}
    params = map(getparams(g)) do p
        v = Symbolics.value(p)
        # check for constant number
        if !(v isa Num)
            vv = simplify(v)
            vvc = unwrap_const(vv)
            vvc isa Number && return vvc
        end

        # check for something that can be evaluated to a number
        if iscall(v)
            vv = Symbolics.value(Symbolics.symbolic_to_float(v))
            vv isa Number && return vv
        end

        # everything else is symbolic (functions or symbols)
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

!!! warning
    For an operator without parameters the returned matrix may be shared by
    every call, so mutating it changes the operator's matrix for the whole
    session. Call `copy` on it before modifying it.

See also [`matrix`](@ref).

## Examples

```jldoctest; setup=:(import MimiqCircuitsBase.unwrappedmatrix)
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
        # check for constant number
        if !(v isa Num)
            vv = simplify(v)
            vvc = unwrap_const(vv)
            vvc isa Number && return vvc
        end

        # check for something that can be evaluated to a number
        if iscall(v)
            vv = Symbolics.value(Symbolics.symbolic_to_float(v))
            vv isa Number && return vv
        end

        # everything else is symbolic (functions or symbols)
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
    rescale(op, a)

Return the operator ``a A`` for an operator ``A`` and a scalar ``a``.

`op` is not modified. A gate becomes a [`RescaledGate`](@ref).
"""
function rescale(op::AbstractOperator, _)
    error("oprescale not implemented for $(typeof(op)).")
end

# `v` written in units of π ("π/2", "-1π/4", "2π"), or `nothing` if it is not
# close to a simple rational multiple of π.
function _pifraction(v::Float64)
    div = v / π
    divint = round(Int, div)
    divrational = rationalize(div)

    if div == divint
        return string(divint) * "π"
    elseif isapprox(divrational, div; rtol=eps(div)) && (divrational.den < 10 || divrational.num == 1)
        numstring = divrational.num == 1 ? "" : string(divrational.num)
        return numstring * "π/" * string(divrational.den)
    end

    return nothing
end

"""
    _displaypi(io, x)

Text for the parameter `x` in an operation listing: a numeric `Num` that is a
simple rational multiple of π is written in units of π (`π/4`, `3π/2`), any
other `Num` in full. Plain numbers go through `_displaynum`, so values
shortened by a `:compact` `io` are marked with `…`.
"""
function _displaypi(::IO, num::Num)
    v = Symbolics.value(num)

    if v isa Float64
        s = _pifraction(v)
        return isnothing(s) ? string(v) : s
    end

    # An exact constant such as `π / 2` prints like the equivalent float,
    # as `π/2`, so exact and floating-point angles display the same way.
    if iscall(v) && !issymbolic(num)
        f = unwrapvalue(num)
        if f isa Float64
            s = _pifraction(f)
            isnothing(s) || return s
        end
    end

    return string(v)
end

_displaypi(io::IO, x) = _displaynum(io, x)

function Base.show(io::IO, ::MIME"text/plain", op::AbstractOperator)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    print(io, opname(op))
    if numparams(op) > 0
        print(io, "(")
        join(io, map(x -> _displaypi(io, getparam(op, x)), parnames(op)), sep)
        print(io, ")")
    end
end

function Base.show(io::IO, op::AbstractOperator)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    print(io, Base.typename(typeof(op)).name)
    print(io, "(")
    join(io, map(x -> _displaypi(io, getparam(op, x)), parnames(op)), sep)
    print(io, ")")
end
