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
    SigmaMinus(a)

One-qubit operator corresponding to ``|0 \rangle\langle 1|``.

The corresponding matrix
```math
\begin{pmatrix}
    0 & a\\
    0 & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`SigmaPlus`](@ref).

## Examples

```jldoctests
julia> SigmaMinus()
SigmaMinus(1)

julia> SigmaMinus(0.5)
SigmaMinus(0.5)

julia> push!(Circuit(), ExpectationValue(SigmaMinus()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨SigmaMinus(1)⟩ @ q[1], z[1]
```
"""
struct SigmaMinus <: AbstractOperator{1}
    a::Num
end

SigmaMinus() = SigmaMinus(1)

opname(::Type{<:SigmaMinus}) = "SigmaMinus"

_matrix(::Type{SigmaMinus}, a) = [0 a; 0 0]

opsquared(op::SigmaMinus) = Projector1(abs2(op.a))


@doc raw"""
    SigmaPlus(a)

One-qubit operator corresponding to ``|1 \rangle\langle 0|``.

The corresponding matrix
```math
\begin{pmatrix}
    0 & 0\\
    a & 0
\end{pmatrix}
```
is parametrized by ``a`` to allow for phases/rescaling.

The parameter ``a`` is optional and is set to 1 by default.

See also [`SigmaMinus`](@ref).

## Examples

```jldoctests
julia> SigmaPlus()
SigmaPlus(1)

julia> SigmaPlus(0.5)
SigmaPlus(0.5)

julia> push!(Circuit(), ExpectationValue(SigmaPlus()), 1, 1)
1-qubit circuit with 1 instructions:
└── ⟨SigmaPlus(1)⟩ @ q[1], z[1]
```
"""
struct SigmaPlus <: AbstractOperator{1}
    a::Num
end

SigmaPlus() = SigmaPlus(1)

opname(::Type{<:SigmaPlus}) = "SigmaPlus"

_matrix(::Type{SigmaPlus}, a) = [0 0; a 0]

opsquared(op::SigmaPlus) = Projector0(abs2(op.a))

for sigma in [SigmaMinus, SigmaPlus]
    eval(quote
        rescale(op::$sigma, scale) = $sigma(op.a * scale)

        function rescale!(op::$sigma, scale)
            op.a *= scale
            return op
        end
    end)
end
