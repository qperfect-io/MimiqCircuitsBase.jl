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

@doc raw"""
    Operator(matrix)

`N` qubit operator specified by an ``2^N \times 2^N`` matrix.

!!! note
    Only one and two qubits operators are supported.

This operator doesn't have to be unitary.

See also [`AbstractOperator`](@ref), [`ExpectationValue`](@ref),
and [`Kraus`](@ref).

## Examples

```jldoctests
julia> Operator([1 2; 3 4])
1-qubit Operator:
├── 1.0 2.0
└── 3.0 4.0

julia> Operator([1 0 0 1; 0 0 0 0; 0 0 0 0; 1 0 0 1])
2-qubit Operator:
├── 1.0 0.0 0.0 1.0
├── 0.0 0.0 0.0 0.0
├── 0.0 0.0 0.0 0.0
└── 1.0 0.0 0.0 1.0
```

Operators can be used for expectation values:

```jldoctests
julia> push!(Circuit(), ExpectationValue(Operator([0 1; 0 0])), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨Operator([0.0 1.0; 0.0 0.0])⟩ @ q[1], z[1]
```
"""
struct Operator{N} <: AbstractOperator{N}
    O::Matrix{Complex{Num}}

    function Operator{N}(O) where {N}
        if N < 1
            error("Cannot define a 0-qubit operator")
        end
        if N > 2
            error("Operators larger than 2 qubits are not supported")
        end

        M = 1 << N
        if ndims(O) != 2 || size(O, 1) != M || size(O, 2) != M
            throw(ArgumentError("Operator should be $(M)×$(M)."))
        end

        return new{N}(O)
    end
end

function Operator(O::AbstractMatrix)
    dim = size(O, 1)

    if !isvalidpowerof2(dim)
        throw(ArgumentError("Dimension of operator has to be 2^N with N >= 1."))
    end

    N = Int(log2(dim))

    fO = float.(O)
    Operator{N}(fO)
end

opname(::Type{<:Operator}) = "Operator"

matrix(g::Operator) = g.O

_matrix(::Type{<:Operator{N}}, O...) where {N} = reshape(collect(O), 2^N, 2^N)

function unwrappedmatrix(op::Operator)
    return unwrapvalue.(op.O)
end

parnames(::Operator{N}) where {N} = tuple(1:2^(2N)...)

parnames(::Type{<:Operator{N}}) where {N} = tuple(1:2^(2N)...)

getparam(op::Operator, i) = op.O[i]

getparams(op::Operator) = op.O

function opsquared(op::Operator{N}) where {N}
    O = matrix(op)
    return Operator{N}(O' * O)
end

rescale(op::Operator, scale) = Operator(scale * matrix(op))

function rescale!(p::Operator, scale)
    p.O *= scale
    return p
end

function Base.show(io::IO, op::Operator{N}) where {N}
    print(io, "Operator", "(")
    io1 = IOContext(io, :compact => get(io, :compact, false), :typeinfo => Array{Symbolics.Num})
    print(io1, _decomplex(matrix(op)))
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", op::Operator{N}) where {N}
    U = _decomplex(matrix(op))
    if get(io, :compact, false)
        print(io, opname(op))
        if get(io, :limit, false) && N > 1
            print(io, "(…)")
            return nothing
        end
        print(io, "([")

        if N <= 1
            join(io, map(x -> join(x, " "), eachrow(U)), "; ")
        else
            join(io, U[1:2], " ")
            print(io, " … ")
            join(io, U[end-1:end], " ")
        end
        print(io, "])")
        return nothing
    end

    print(io, numqubits(op), "-qubit ", opname(op), ":\n")
    a = axes(U, 1)
    for i in a[1:end-1]
        print(io, "├── ")
        join(io, U[i, :], " ")
        print(io, '\n')
    end
    print(io, "└── ")
    join(io, U[a[end], :], " ")
end
