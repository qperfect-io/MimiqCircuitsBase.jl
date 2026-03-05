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
    GateCSX()

    Two qubit Controled-SX gate.

!!! details
    Implemented as an alias to `Control(1, GateSX())`.

See also [`GateSX`](@ref), [`GateCSXDG`](@ref), [`Control`](@ref).

## Matrix representation

```math
\operatorname{CSX} =\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & \frac{1+i}{2} & \frac{1-i}{2} \\
    0 & 0 & \frac{1-i}{2} & \frac{1+i}{2}
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCSX(), numcontrols(GateCSX()), numtargets(GateCSX())
(GateCSX(), 1, 1)

julia> matrix(GateCSX())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.5+0.5im  0.5-0.5im
 0.0+0.0im  0.0+0.0im  0.5-0.5im  0.5+0.5im

julia> c = push!(Circuit(), GateCSX(), 1, 2)
2-qubit circuit with 1 instruction:
└── CSX @ q[1], q[2]

julia> power(GateCSX(), 2), inverse(GateCSX())
(GateCX(), Control(Inverse(GateSX())))

```

## Decomposition

```jldoctests
julia> decompose(GateCSX())
2-qubit circuit with 7 instructions:
├── U(π/2,0,π) @ q[2]
├── U(0,0,π/4) @ q[1]
├── CX @ q[1], q[2]
├── U(0,0,-1π/4) @ q[2]
├── CX @ q[1], q[2]
├── U(0,0,π/4) @ q[2]
└── U(π/2,0,π) @ q[2]

```
"""
const GateCSX = typeof(Control(1, GateSX()))

@definename GateCSX "CSX"

matches(::CanonicalRewrite, ::GateCSX) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateCSX, qtargets, _, _)
    a, b = qtargets
    push!(builder, GateH(), b)
    push!(builder, GateCS(), a, b)
    push!(builder, GateH(), b)
    return builder
end

@doc raw"""
    GateCSXDG()

Two qubit CSX-dagger gate. (Control on second qubit)

!!! details
    Implemented as an alias to `Control(1, GateSXDG())`.

See also [`GateSX`](@ref), [`GateCSXDG`](@ref), [`Control`](@ref).

## Matrix representation

```math
\operatorname{CSX}^{\dagger} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0
    0 & 0 & \frac{1-i}{2} & \frac{1+i}{2} \\
    0 & 0 & \frac{1+i}{2} & \frac{1-i}{2}
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCSXDG(), numcontrols(GateCSXDG()), numtargets(GateCSXDG())
(Control(Inverse(GateSX())), 1, 1)

julia> matrix(GateCSXDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.5-0.5im  0.5+0.5im
 0.0+0.0im  0.0+0.0im  0.5+0.5im  0.5-0.5im

julia> c = push!(Circuit(), GateCSXDG(), 1, 2)
2-qubit circuit with 1 instruction:
└── C(SX†) @ q[1], q[2]

julia> power(GateCSXDG(), 2), inverse(GateCSXDG())
(Control((Inverse(GateSX()))^2), GateCSX())

```

## Decomposition

```jldoctests
julia> decompose(GateCSXDG())
2-qubit circuit with 7 instructions:
├── U(π/2,0,π) @ q[2]
├── U(0,0,-1π/4) @ q[1]
├── CX @ q[1], q[2]
├── U(0,0,π/4) @ q[2]
├── CX @ q[1], q[2]
├── U(0,0,-1π/4) @ q[2]
└── U(π/2,0,π) @ q[2]

```
"""
const GateCSXDG = typeof(inverse(GateCSX()))

matches(::CanonicalRewrite, ::GateCSXDG) = true

function decompose_step!(builder, ::CanonicalRewrite, ::GateCSXDG, qtargets, _, _)
    a, b = qtargets
    push!(builder, GateH(), b)
    push!(builder, GateCSDG(), a, b)
    push!(builder, GateH(), b)
    return builder
end
