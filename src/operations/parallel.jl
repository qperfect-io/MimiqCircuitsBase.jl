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
    Parallel(repeats, operation)

Wrapper that applies the same operation on multiple qubits.

If the operation is a `N`-qubit operation, then the resulting operation is
applied over `N * repeats` qubits.

## Examples

```jldoctests; setup = :(@variables λ)
julia> Parallel(5, GateX())
Parallel(5, X)

julia> Parallel(3, GateRX(λ))
Parallel(3, RX(λ))

julia> Parallel(2, Parallel(3, GateX()))
Parallel(2, Parallel(3, X))

```

## Decomposition

A parallel is decomposed into a sequence of operation, one for each group of qubits.

```jldoctests
julia> decompose(Parallel(2, GateX()))
2-qubit circuit with 2 instructions:
├── X @ q1
└── X @ q2

julia> decompose(Parallel(3, GateSWAP()))
6-qubit circuit with 3 instructions:
├── SWAP @ q1, q4
├── SWAP @ q2, q5
└── SWAP @ q3, q6
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

qregsizes(::Parallel{N,M}) where {N,M} = ntuple(x -> M, N)

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

function Base.show(io::IO, p::Parallel)
    print(io, opname(p), "(", numrepeats(p), ", ", getoperation(p), ")")
end

@generated function _matrix(::Type{Parallel{N,M,L,T}}) where {N,M,L,T}
    mat = _matrix(T)
    return kron([mat for _ in 1:N]...)
end

function _matrix(::Type{Parallel{N,M,L,T}}, args...) where {N,M,L,T}
    mat = _matrix(T, args...)
    return kron([mat for _ in 1:N]...)
end

function decompose!(circ::Circuit, p::Parallel, qtargets, _)
    op = getoperation(p)
    targets = reshape(qtargets, (numrepeats(p), numqubits(op)))
    push!(circ, getoperation(p), eachcol(targets)...)
end
