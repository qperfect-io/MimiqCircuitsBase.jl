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

@doc raw"""
    GateCSX()

Two qubit Controlled-SX gate. (Control on second qubit)

!!! details
    Implemented as an alias to `Control(1, GateSX())`.

See also [`GateSX`](@ref), [`GateCSXDG`](@ref), [`Control`](@ref).

## Matrix representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & \frac{1+i}{\sqrt{2}} & 0 & \frac{1-i}{\sqrt{2}} \\
    0 & 0 & 1 & 0 \\
    0 & \frac{1-i}{\sqrt{2}} & 0 & \frac{1+i}{\sqrt{2}}
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCSX(), numcontrols(GateCSX()), numtargets(GateCSX())
(CSX, 1, 1)

julia> matrix(GateCSX())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.5+0.5im  0.5-0.5im
 0.0+0.0im  0.0+0.0im  0.5-0.5im  0.5+0.5im

julia> c = push!(Circuit(), GateCSX(), 1, 2)
2-qubit circuit with 1 instructions:
└── CSX @ q1, q2

julia> power(GateCSX(), 2), inverse(GateCSX())
(CX, C(SX†))

```

## Decomposition

```jldoctests
julia> decompose(GateCSX())
2-qubit circuit with 3 instructions:
├── H @ q2
├── CU1(π/2) @ q1, q2
└── H @ q2

```
"""
const GateCSX = typeof(Control(1, GateSX()))

function decompose!(circ::Circuit, ::GateCSX, qtargets, _)
    a, b = qtargets
    push!(circ, GateH(), b)
    push!(circ, Control(GateU1(π / 2)), a, b)
    push!(circ, GateH(), b)
    return circ
end

@doc raw"""
    GateCSXDG()

Two qubit CSX-dagger gate. (Control on second qubit)

!!! details
    Implemented as an alias to `Control(1, GateSXDG())`.

See also [`GateSX`](@ref), [`GateCSXDG`](@ref), [`Control`](@ref).

## Matrix representation

```math
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & \frac{1-i}{\sqrt{2}} & 0 & \frac{1+i}{\sqrt{2}} \\
    0 & 0 & 1 & 0 \\
    0 & \frac{1+i}{\sqrt{2}} & 0 & \frac{1-i}{\sqrt{2}}
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCSXDG(), numcontrols(GateCSXDG()), numtargets(GateCSXDG())
(C(SX†), 1, 1)

julia> matrix(GateCSXDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.5-0.5im  0.5+0.5im
 0.0+0.0im  0.0+0.0im  0.5+0.5im  0.5-0.5im

julia> c = push!(Circuit(), GateCSXDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── C(SX†) @ q1, q2

julia> power(GateCSXDG(), 2), inverse(GateCSXDG())
(C(SX†^2), CSX)

```

## Decomposition

```jldoctests
julia> decompose(GateCSXDG())
2-qubit circuit with 3 instructions:
├── H @ q2
├── CU1(-1π/2) @ q1, q2
└── H @ q2

```
"""
const GateCSXDG = typeof(inverse(GateCSX()))

function decompose!(circ::Circuit, ::GateCSXDG, qtargets, _)
    a, b = qtargets
    push!(circ, GateH(), b)
    push!(circ, Control(GateU1(-π / 2)), a, b)
    push!(circ, GateH(), b)
    return circ
end
