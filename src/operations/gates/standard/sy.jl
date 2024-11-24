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
    GateSY()

Single qubit ``\sqrt{Y}`` gate.

See also [`GateSYDG`](@ref), [`GateY`](@ref), [`Power`](@ref)

## Matrix representation

```math
\operatorname{SY} =
\sqrt{\operatorname{Y}} =
\frac{1}{2}
\begin{pmatrix}
    1+i & -1-i \\
    1+i & 1+i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSY()
SY

julia> matrix(GateSY())
2×2 Matrix{ComplexF64}:
 0.5+0.5im  -0.5-0.5im
 0.5+0.5im   0.5+0.5im

julia> c = push!(Circuit(), GateSY(), 1)
1-qubit circuit with 1 instructions:
└── SY @ q[1]

julia> push!(c, GateSY, 2)
2-qubit circuit with 2 instructions:
├── SY @ q[1]
└── SY @ q[2]

julia> power(GateSY(), 2)
Y

```

## Decomposition

```jldoctests
julia> decompose(GateSY())
1-qubit circuit with 4 instructions:
├── S @ q[1]
├── S @ q[1]
├── H @ q[1]
└── U(0,0,0,π/4) @ q[1]
```
"""
const GateSY = typeof(power(GateY(), 1 // 2))

@definename GateSY "SY"

function decompose!(circ::Circuit, ::GateSY, qtargets, _, _)
    a = qtargets[1]
    push!(circ, GateS(), a)
    push!(circ, GateS(), a)
    push!(circ, GateH(), a)
    push!(circ, GateU(0, 0, 0, π / 4), a)
    return circ
end

@generated _matrix(::Type{GateSY}) = ComplexF64[0.5+0.5im -0.5-0.5im; 0.5+0.5im 0.5+0.5im]

@doc raw"""
    GateSYDG()

Single qubit ``\sqrt{Y}^\dagger`` gate (conjugate transpose of the ``\sqrt{Y}``
gate)

See also [`GateSY`](@ref), [`GateY`](@ref), [`Power`](@ref), [`Inverse`](@ref)

## Matrix representation

```math
\operatorname{SYDG} =
\sqrt{\operatorname{Y}}^\dagger =
\frac{1}{2}
\begin{pmatrix}
    1-i & 1-i \\
    -1+i & 1-i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSYDG()
SY†

julia> matrix(GateSYDG())
2×2 adjoint(::Matrix{ComplexF64}) with eltype ComplexF64:
  0.5-0.5im  0.5-0.5im
 -0.5+0.5im  0.5-0.5im

julia> c = push!(Circuit(), GateSYDG(), 1)
1-qubit circuit with 1 instructions:
└── SY† @ q[1]

julia> push!(c, GateSYDG, 2)
2-qubit circuit with 2 instructions:
├── SY† @ q[1]
└── SY† @ q[2]

julia> power(GateSYDG(), 2)
(SY†)^2

julia> inverse(GateSYDG())
SY

```
"""
const GateSYDG = typeof(inverse(GateSY()))

function decompose!(circ::Circuit, ::GateSYDG, qtargets, _, _)
    a = qtargets[1]
    push!(circ, GateU(0, 0, 0, -π / 4), a)
    push!(circ, GateH(), a)
    push!(circ, GateSDG(), a)
    push!(circ, GateSDG(), a)
    return circ
end

@generated _gate(::Type{GateSYDG}) = [0.5-0.5im 0.5-0.5im; -0.5+0.5im 0.5-0.5im]
