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
    Parallel(repeats, operation)

Wrapper that applies the same operation on multiple qubits.

If the operation is a `N`-qubit operation, then the resulting operation is
applied over `N * repeats` qubits.

## Examples

```jldoctests; setup = :(@variables λ)
julia> Parallel(5, GateX())
⨷ ⁵ X

julia> Parallel(3, GateRX(λ))
⨷ ³ RX(λ)

julia> Parallel(2, Parallel(3, GateX()))
⨷ ² (⨷ ³ X)

```

## Decomposition

A parallel is decomposed into a sequence of operation, one for each group of qubits.

```jldoctests
julia> decompose(Parallel(2, GateX()))
2-qubit circuit with 2 instructions:
├── X @ q[1]
└── X @ q[2]

julia> decompose(Parallel(3, GateSWAP()))
6-qubit circuit with 3 instructions:
├── SWAP @ q[1:2]
├── SWAP @ q[3:4]
└── SWAP @ q[5:6]
```
"""
struct Parallel{N,M,L,T<:AbstractGate{M}} <: AbstractGate{L}
    op::T

    function Parallel{N,M,L,T}(args...) where {N,M,L,T<:AbstractGate{M}}
        @assert N isa Integer
        @assert M isa Integer
        @assert L isa Integer
        @assert N > 0
        @assert M > 0
        @assert N * M == L
        new{N,M,L,T}(T(args...))
    end

    function Parallel(repeats::Integer, op::T) where {N,T<:AbstractGate{N}}
        if repeats < 1
            throw(ArgumentError("Invalid number of repetitions, must be > 1."))
        end

        new{repeats,N,repeats * N,T}(op)
    end
end

opname(::Type{<:Parallel}) = "Parallel"

iswrapper(::Type{<:Parallel}) = true

getoperation(p::Parallel) = p.op

parnames(::Type{Parallel{N,M,L,T}}) where {N,M,L,T} = parnames(T)

qregsizes(op::Parallel{N}) where {N} = Tuple(repeat(collect(qregsizes(getoperation(op))); outer=N))

getparam(p::Parallel, name) = getparam(getoperation(p), name)

# parallel and inverse commute.
# we always prefer parallel to be applied last
inverse(p::Parallel{N}) where {N} = Parallel(N, inverse(p.op))

# parallel and power commute.
# we always prefer parallel to be applied last
_power(p::Parallel{N}, n::Integer) where {N} = Parallel(n * N, _power(p.op, n))

"""
    numrepeats(paralleloperation)

Get the number of repetitions of a parallel operation.

See also [`Parallel`](@ref).
## Examples

```jldoctests
julia> numrepeats(Parallel(5, GateX()))
5

julia> numrepeats(Parallel(3, GateSWAP()))
3

```
"""
function numrepeats end

numrepeats(::Type{<:Parallel{N}}) where {N} = N

numrepeats(::T) where {T<:Parallel} = numrepeats(T)

@generated function _matrix(::Type{Parallel{N,M,L,T}}) where {N,M,L,T}
    mat = _matrix(T)
    return kron([mat for _ in 1:N]...)
end

function _matrix(::Type{Parallel{N,M,L,T}}, args...) where {N,M,L,T}
    mat = _matrix(T, args...)
    return kron([mat for _ in 1:N]...)
end

function decompose!(circ::Circuit, p::Parallel, qtargets, _, _)
    op = getoperation(p)
    nq = numqubits(op)
    for i in 1:numrepeats(p)
        push!(circ, op, qtargets[nq*(i-1).+(1:nq)]...)
    end
    return circ
end

"""
    parallel(repeats, operation)

Build a parallel operation.

The resulting operation is applied over `N * repeats` qubits.
"""
function parallel end

parallel(numrepeats::Integer, op::Operation{N,0}) where {N} = Parallel(numrepeats, op)

parallel(op::Operation{N,0}) where {N} = LazyExpr(parallel, LazyArg(), op)
parallel(num_repeats, l::LazyExpr) = LazyExpr(parallel, num_repeats, l)
parallel(l::LazyExpr) = LazyExpr(parallel, LazyArg(), l)

function Base.show(io::IO, p::Parallel)
    print(io, opname(p), "(", numrepeats(p), ", ", getoperation(p), ")")
end

function Base.show(io::IO, m::MIME"text/plain", p::Parallel)
    print(io, "⨷ ")
    superscript = collect("⁰¹²³⁴⁵⁶⁷⁸⁹")
    for i in reverse(digits(numrepeats(p)))
        print(io, superscript[Int(i)+1])
    end
    print(io, " ")
    _show_wrapped_parens(io, m, getoperation(p))
end
