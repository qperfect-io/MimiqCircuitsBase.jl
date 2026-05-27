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

@doc raw"""
    LossyOperator(matrix, lossy)
    LossyOperator(matrix)              # 1-qubit shorthand, lossy = (1,)

Tagged custom ``N``-qubit operator representing a loss branch in a
[`Kraus`](@ref) channel, annotated with the qubits that leak.

The operator is a ``2^N \times 2^N`` matrix in the computational basis (same
ordering as [`Operator`](@ref)) plus a tuple `lossy` of qubit indices in `1:N`
listing **which of the operator's qubits leak** when this branch is selected.

A `Kraus` channel that contains one or more `LossyOperator` branches is a
loss-aware channel; the helpers [`hasloss`](@ref), [`lossoperators`](@ref),
[`survivaloperators`](@ref), and [`losseffect`](@ref) inspect those branches.
Qubit identity is positional: when the surrounding `Kraus` channel is pushed
onto a circuit with target qubits ``q_1,\dots,q_N``, the physical qubit
``q_i`` is marked as lost for every ``i \in`` `lossy`. The order of operators
inside the channel carries no semantic meaning.

See also [`Operator`](@ref), [`Kraus`](@ref).

## Arguments

* `matrix`: A ``2^N \times 2^N`` complex matrix.
* `lossy`: One or more qubit indices in `1:N`. May be passed as a tuple
  (`(1, 2)`), a vector (`[2]`), or a single integer (`2`). Order is canonical
  (sorted ascending); duplicates are not allowed; the set must be non-empty.

## Examples

```jldoctests
julia> LossyOperator([0 1; 0 0])
LossyOperator(0.0, 0.0, 1.0, 0.0; lossy=(1,))

julia> push!(Circuit(), Kraus([[1 0; 0 sqrt(0.9)], LossyOperator([0 sqrt(0.1); 0 0])]), 1)
1-qubit circuit with 1 instruction:
└── Kraus(Operator([1.0 0.0; 0.0 0.948683]), LossyOperator(0.0,0.0,0.316228,0.0;lossy=(1,))) @ q[1]
```
"""
struct LossyOperator{N} <: AbstractOperator{N}
    O::Matrix{Complex{Num}}
    lossy::Tuple{Vararg{Int}}

    function LossyOperator{N}(O::AbstractMatrix, lossy::Tuple{Vararg{Int}}) where {N}
        if N < 1
            error("Cannot define a 0-qubit lossy operator")
        end
        if N > 2
            error("Lossy operators larger than 2 qubits are not supported")
        end

        M = 1 << N
        if ndims(O) != 2 || size(O, 1) != M || size(O, 2) != M
            throw(ArgumentError("LossyOperator should be $(M)×$(M)."))
        end

        if isempty(lossy)
            throw(ArgumentError("LossyOperator must mark at least one lossy qubit."))
        end
        if !all(1 <= q <= N for q in lossy)
            throw(ArgumentError("Lossy qubit indices must be in 1:$N, got $lossy."))
        end
        if length(unique(lossy)) != length(lossy)
            throw(ArgumentError("Lossy qubit indices must be unique, got $lossy."))
        end

        return new{N}(float.(O), Tuple(sort!(collect(lossy))))
    end
end

LossyOperator{N}(O::AbstractMatrix, lossy) where {N} =
    LossyOperator{N}(O, _normalize_lossy(lossy))

function LossyOperator(O::AbstractMatrix, lossy)
    dim = size(O, 1)
    if !isvalidpowerof2(dim)
        throw(ArgumentError("Dimension of LossyOperator has to be 2^N with N >= 1."))
    end
    N = Int(log2(dim))
    return LossyOperator{N}(O, _normalize_lossy(lossy))
end

function LossyOperator(O::AbstractMatrix)
    dim = size(O, 1)
    if !isvalidpowerof2(dim)
        throw(ArgumentError("Dimension of LossyOperator has to be 2^N with N >= 1."))
    end
    N = Int(log2(dim))
    if N != 1
        throw(ArgumentError("LossyOperator on $N qubits requires explicit lossy qubit indices."))
    end
    return LossyOperator{1}(O, (1,))
end

_normalize_lossy(lossy::Tuple{Vararg{Integer}}) = Tuple(Int(q) for q in lossy)
_normalize_lossy(lossy::AbstractVector{<:Integer}) = Tuple(Int(q) for q in lossy)
_normalize_lossy(lossy::Integer) = (Int(lossy),)

opname(::Type{<:LossyOperator}) = "LossyOperator"

_matrix(::Type{<:LossyOperator{N}}, O...) where {N} = reshape(collect(O), 2^N, 2^N)

parnames(::LossyOperator{N}) where {N} = tuple(1:2^(2N)...)

parnames(::Type{<:LossyOperator{N}}) where {N} = tuple(1:2^(2N)...)

getparam(g::LossyOperator, i) = g.O[i]

getparams(g::LossyOperator) = vec(g.O)

"""
    lossyqubits(op)

Return the tuple of qubit indices (within the operator's own `1:N` numbering)
that this [`LossyOperator`](@ref) marks as lost.
"""
lossyqubits(op::LossyOperator) = op.lossy

"""
    lossytargets(op, targets)
    lossytargets(op, targets...)

Translate the operator-relative `lossy` indices into the corresponding physical
qubit targets. `targets` is the tuple of physical qubit targets the surrounding
instruction acts on (length must match `numqubits(op)`).

Returns an `NTuple{K, eltype(targets)}` where `K = length(lossyqubits(op))` —
the physical qubits that should be marked as lost when this branch is selected
during simulation.

## Examples

```jldoctests
julia> op = LossyOperator(zeros(4, 4), 2);     # 2-qubit, qubit 2 is lossy

julia> lossytargets(op, (3, 7))
(7,)

julia> both = LossyOperator(zeros(4, 4), (1, 2));

julia> lossytargets(both, (3, 7))
(3, 7)
```
"""
function lossytargets(op::LossyOperator{N}, targets::Tuple) where {N}
    if length(targets) != N
        throw(ArgumentError("Expected $N targets for a $N-qubit LossyOperator, got $(length(targets))."))
    end
    return ntuple(i -> targets[lossyqubits(op)[i]], length(lossyqubits(op)))
end

lossytargets(op::LossyOperator, targets...) = lossytargets(op, targets)

function unwrappedmatrix(op::LossyOperator)
    return unwrapvalue.(op.O)
end

function opsquared(op::LossyOperator)
    return Operator(matrix(op)' * matrix(op))
end

rescale(op::LossyOperator, scale) = LossyOperator(scale * matrix(op), op.lossy)

function rescale!(op::LossyOperator, scale)
    op.O .*= scale
    return op
end

function Base.show(io::IO, op::LossyOperator)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    tail = compact ? ";lossy=" : "; lossy="
    print(io, opname(op), "(")
    join(io, map(x -> _displaypi(getparam(op, x)), parnames(op)), sep)
    print(io, tail, op.lossy, ")")
end

function Base.show(io::IO, ::MIME"text/plain", op::LossyOperator)
    show(io, op)
end

function Base.:(==)(left::LossyOperator, right::LossyOperator)
    typeof(left) == typeof(right) || return false
    left.lossy == right.lossy || return false

    for (l, r) in zip(matrix(left), matrix(right))
        issymbolic(l) == issymbolic(r) || return false

        if issymbolic(l) && issymbolic(r)
            l === r || return false
        end

        isequal(l, r) || return false
    end

    return true
end
