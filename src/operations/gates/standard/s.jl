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
    GateS()

Single qubit ``S`` gate (or phase gate).
It is defined as the square root of the ``Z`` gate.

See also [`GateSDG`](@ref), [`GateZ`](@ref), [`Power`](@ref)

## Matrix representation

```math
\operatorname{S} =
\sqrt{\operatorname{Z}} =
\begin{pmatrix}
    1 & 0 \\
    0 & i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateS()
S

julia> matrix(GateS())
2×2 Matrix{Complex{Int64}}:
 1+0im  0+0im
 0+0im  0+1im

julia> c = push!(Circuit(), GateS(), 1)
1-qubit circuit with 1 instructions:
└── S @ q[1]

julia> push!(c, GateS, 2)
2-qubit circuit with 2 instructions:
├── S @ q[1]
└── S @ q[2]

julia> power(GateS(), 2), inverse(GateS())
(GateZ(), Inverse(GateS()))

```

## Decomposition

```jldoctests
julia> decompose(GateS())
1-qubit circuit with 1 instructions:
└── U(0,0,π/2) @ q[1]

```
"""
const GateS = typeof(power(GateZ(), 1 // 2))

@definename GateS "S"

function decompose!(circ::Circuit, ::GateS, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, π / 2), q)
    return circ
end

@generated _matrix(::Type{GateS}) = [1 0; 0 im]

@doc raw"""
    GateSDG()

Single qubit S-dagger gate (conjugate transpose of the S gate).

See also [`GateS`](@ref), [`GateZ`](@ref), [`Power`](@ref), [`Inverse`](@ref)

## Matrix representation

```math
\operatorname{S}^\dagger =
\begin{pmatrix}
    1 & 0 \\
    0 & -i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSDG()
S†

julia> matrix(GateSDG())
2×2 Matrix{Complex{Int64}}:
 1+0im  0+0im
 0+0im  0-1im

julia> c = push!(Circuit(), GateSDG(), 1)
1-qubit circuit with 1 instructions:
└── S† @ q[1]

julia> push!(c, GateSDG, 2)
2-qubit circuit with 2 instructions:
├── S† @ q[1]
└── S† @ q[2]

julia> power(GateSDG(), 2), inverse(GateSDG())
((Inverse(GateS()))^2, GateS())

```

## Decomposition

```jldoctests
julia> decompose(GateSDG())
1-qubit circuit with 1 instructions:
└── U(0,0,-1π/2) @ q[1]

```
"""
const GateSDG = typeof(inverse(GateS()))

function decompose!(circ::Circuit, ::GateSDG, qtargets, _, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, -π / 2), q)
    return circ
end

@generated _matrix(::Type{GateSDG}) = [1 0; 0 -im]
