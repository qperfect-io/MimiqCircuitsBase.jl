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

@doc raw"""
    GateT()

Single qubit T gate.
It is defined as the square root of the ``S`` gate, ``Z^{\frac{1}{4}}``.

See also [`GateTDG`](@ref), [`GateS`](@ref), [`GateZ`](@ref), [`Power`](@ref)

## Matrix representation

```math
\operatorname{Z} =
\operatorname{Z}^{\frac{1}{4}} =
\begin{pmatrix}
    1 & 0 \\
    0 & \exp(\frac{i\pi}{4})
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateT()
T

julia> matrix(GateT())
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107+0.707107im

julia> c = push!(Circuit(), GateT(), 1)
1-qubit circuit with 1 instruction:
└── T @ q[1]

julia> push!(c, GateT, 2)
2-qubit circuit with 2 instructions:
├── T @ q[1]
└── T @ q[2]

julia> power(GateT(), 2), power(GateT(), 4), inverse(GateT())
(GateS(), GateZ(), Inverse(GateT()))

```

## Decomposition

```jldoctests
julia> decompose(GateT())
1-qubit circuit with 1 instruction:
└── U(0,0,π/4) @ q[1]

```
"""
const GateT = typeof(power(GateS(), 1 // 2))

@definename GateT "T"

matches(::CanonicalRewrite, ::GateT) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateT, qtargets, _, _)
    q = qtargets[1]
    push!(builder, GateU(0, 0, π / 4), q)
    return builder
end

@generated _matrix(::Type{GateT}) = [1 0; 0 exp(im * π / 4)]

@doc raw"""
    GateTDG()

Single qubit T-dagger gate (conjugate transpose of the T gate).

See also [`GateT`](@ref)

## Matrix Representation

```math
\operatorname{T}^\dagger =
\begin{pmatrix}
    1 & 0 \\
    0 & \exp(\frac{-i\pi}{4})
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateTDG()
T†

julia> matrix(GateTDG())
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.707107-0.707107im

julia> c = push!(Circuit(), GateTDG(), 1)
1-qubit circuit with 1 instruction:
└── T† @ q[1]

julia> push!(c, GateTDG, 2)
2-qubit circuit with 2 instructions:
├── T† @ q[1]
└── T† @ q[2]

julia> power(GateTDG(), 2), power(GateTDG(), 4), inverse(GateTDG())
((Inverse(GateT()))^2, (Inverse(GateT()))^4, GateT())

```

## Decomposition

```jldoctests
julia> decompose(GateTDG())
1-qubit circuit with 1 instruction:
└── U(0,0,-1π/4) @ q[1]

```
"""
const GateTDG = typeof(inverse(GateT()))

matches(::CanonicalRewrite, ::GateTDG) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateTDG, qtargets, _, _)
    q = qtargets[1]
    push!(builder, GateU(0, 0, -π / 4), q)
    return builder
end

@generated _matrix(::Type{GateTDG}) = [1 0; 0 exp(-im * π / 4)]
