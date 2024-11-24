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
    DiagonalOp(a,b)

One-qubit diagonal operator.

The corresponding matrix
```math
\begin{pmatrix}
    a & 0\\
    0 & b
\end{pmatrix}
```
is parametrized by complex numbers `a` and `b`.

See also [`Operator`](@ref), [`Projector0`](@ref), [`Projector1`](@ref).

## Examples

```jldoctests
julia> DiagonalOp(1,0.5)
D(1, 0.5)

julia> push!(Circuit(), ExpectationValue(DiagonalOp(1,0.5)), 1, 2)
1-qubit circuit with 1 instructions:
└── ⟨D(1,0.5)⟩ @ q[1], z[2]
```
"""
struct DiagonalOp <: AbstractOperator{1}
    a::Num
    b::Num
end

DiagonalOp() = DiagonalOp(1, 1)

opname(::Type{<:DiagonalOp}) = "D"

_matrix(::Type{DiagonalOp}, a, b) = [a 0; 0 b]

opsquared(op::DiagonalOp) = DiagonalOp(abs2(op.a), abs2(op.b))

rescale(op::DiagonalOp, scale) = DiagonalOp(op.a * scale, op.b * scale)

function rescale!(op::DiagonalOp, scale)
    op.a *= scale
    op.b *= scale
    op
end
