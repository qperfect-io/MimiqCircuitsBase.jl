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

"""
    Repeat(repeats, operation)

Wrapper that applies the same operation multiple times, on the same qubits, bits, and variables.

## Examples

```jldoctests; setup = :(@variables λ)
julia> Repeat(5, GateX())
∏⁵ X

julia> Repeat(3, GateRX(λ))
∏³ RX(λ)

julia> Repeat(2, Repeat(3, GateX()))
∏² (∏³ X) 

```

## Decomposition

A repeated operation is decomposed by repeating the same operation multiple times

```jldoctests
julia> decompose(Repeat(2, GateX()))
1-qubit circuit with 2 instructions:
├── U(π,0,π) @ q[1]
└── U(π,0,π) @ q[1]

julia> decompose(Repeat(3, GateSWAP()))
2-qubit circuit with 9 instructions:
├── CX @ q[1], q[2]
├── CX @ q[2], q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[2]
├── CX @ q[2], q[1]
├── CX @ q[1], q[2]
├── CX @ q[1], q[2]
├── CX @ q[2], q[1]
└── CX @ q[1], q[2]
```

# Using `repeat`

The repeat function is a shorthand for creating a `Repeat` operation. The main
difference  between using `repeat` and `Repeat` is that the former tries to
infer any simplification that can be done on the operation before
creating a `Repeat` operation.

!!! warn
    `repeat` doesn't always return a `Repeat` operation. For example, it can
    return a `Power` operation.
"""
struct Repeat{R,N,M,L,T<:Operation{N,M,L}} <: Operation{N,M,L}
    op::T

    function Repeat{R,N,M,L,T}(op::T) where {R,N,M,L,T<:Operation{N,M,L}}
        if R < 0
            throw(ArgumentError("Invalid number of repetitions, must be ≥ 0."))
        end
        new{R,N,M,L,T}(op)
    end
end

function Repeat(repeats::Integer, op::T) where {N,M,L,T<:Operation{N,M,L}}
    Repeat{repeats,N,M,L,T}(op)
end

opname(::Type{<:Repeat}) = "Repeat"

iswrapper(::Type{<:Repeat}) = true

getoperation(p::Repeat) = p.op

parnames(::Type{<:Repeat{N,M,L,T}}) where {N,M,L,T} = parnames(T)

qregsizes(op::Repeat{N}) where {N} = qregsizes(getoperation(op))

cregsizes(op::Repeat{N}) where {N} = cregsizes(getoperation(op))

zregsizes(op::Repeat{N}) where {N} = zregsizes(getoperation(op))

getparam(p::Repeat, name) = getparam(getoperation(p), name)

# repeat and inverse commute.
# we always prefer repeat to be applied last
# NOTE: for now, we trust Inverse to return a proper error message
# in the case the wrapped operation is not invertible
inverse(p::Repeat{N}) where {N} = Repeat(N, inverse(p.op))

# NOTE: for now, we trust Power to return a proper error message
# in the case the wrapped operation is not a power
function _power(p::Repeat{N}, n::Integer) where {N}
    if (N * n) % 1 == 0.0
        return Repeat(N * n, p.op)
    end

    return Repeat(N, _power(p.op, n))
end

numrepeats(::Type{<:Repeat{R}}) where {R} = R

numrepeats(::T) where {T<:Repeat} = numrepeats(T)

@generated function _matrix(::Type{Repeat{R,N,M,L,T}}) where {R,N,M,L,T}
    mat = _matrix(T)
    return mat^R
end

function _matrix(::Type{Repeat{R,N,M,L,T}}, args...) where {R,N,M,L,T}
    mat = _matrix(T, args...)
    return mat^R
end

matches(::CanonicalRewrite, ::Repeat) = true

function decompose_step!(builder, ::CanonicalRewrite, p::Repeat, qtargets, ctargets, ztargets)
    op = getoperation(p)
    for _ in 1:numrepeats(p)
        push!(builder, op, qtargets..., ctargets..., ztargets...)
    end
    return builder
end

Base.repeat(numrepeats::Integer, op::Operation) = Repeat(numrepeats, op)
Base.repeat(op::Operation) = LazyExpr(repeat, LazyArg(), op)
Base.repeat(num_repeats, l::LazyExpr) = LazyExpr(repeat, num_repeats, l)
Base.repeat(l::LazyExpr) = LazyExpr(repeat, LazyArg(), l)

function Base.show(io::IO, p::Repeat)
    print(io, opname(p), "(", numrepeats(p), ", ", getoperation(p), ")")
end

function Base.show(io::IO, m::MIME"text/plain", p::Repeat)
    print(io, "∏")
    superscript = collect("⁰¹²³⁴⁵⁶⁷⁸⁹")
    for i in reverse(digits(numrepeats(p)))
        print(io, superscript[Int(i)+1])
    end
    print(io, " ")
    _show_wrapped_parens(io, m, getoperation(p))
end

isunitary(op::Repeat) = isunitary(getoperation(op))

function Base.:(==)(p1::Repeat, p2::Repeat)
    numrepeats(p1) == numrepeats(p2) || return false
    getoperation(p1) == getoperation(p2) || return false
    return true
end
