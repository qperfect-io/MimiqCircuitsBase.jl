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
    GateCX()

Two qubit Controlled-``X`` gate (or CNOT).

!!! details
    Implemented as an alias to `Control(1, GateX())`.

!!! note
    By convention we refer to the first qubit as the control qubit and the
    second qubit as the target.

## Matrix representation

```math
\operatorname{CX} =
\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & 1 \\
    0 & 0 & 1 & 0
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCX(), numcontrols(GateCX()), numtargets(GateCX())
(CX, 1, 1)

julia> matrix(GateCX())
4×4 Matrix{Float64}:
 1.0  0.0  0.0  0.0
 0.0  1.0  0.0  0.0
 0.0  0.0  0.0  1.0
 0.0  0.0  1.0  0.0

julia> c = push!(Circuit(), GateCX(), 1, 2)
2-qubit circuit with 1 instructions:
└── CX @ q1, q2

julia> power(GateCX(), 2), inverse(GateCX())
(CID, CX)

```

## Decomposition

```jldoctests
julia> decompose(GateCX())
2-qubit circuit with 2 instructions:
├── CU(π, 0, π) @ q1, q2
└── CGPhase(-1π/2) @ q1, q2

```
"""
const GateCX = typeof(Control(GateX()))

@doc raw"""
    GateCY()

Two qubit Controlled-``Y`` gate.

!!! details
    Implemented as an alias to `Control(1, GateY())`.

!!! note
    By convention we refer to the first qubit as the control qubit and the
    second qubit as the target.

## Matrix representation

```math
\operatorname{CY} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 0 & -i \\
    0 & 0 & i & 0
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCY(), numcontrols(GateCY()), numtargets(GateCY())
(CY, 1, 1)

julia> matrix(GateCY())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0-1.0im
 0.0+0.0im  0.0+0.0im  0.0+1.0im  0.0+0.0im

julia> c = push!(Circuit(), GateCY(), 1, 2)
2-qubit circuit with 1 instructions:
└── CY @ q1, q2

julia> power(GateCY(), 2), inverse(GateCY())
(CID, CY)

```

## Decomposition

```jldoctests
julia> decompose(GateCY())
2-qubit circuit with 3 instructions:
├── S† @ q2
├── CX @ q1, q2
└── S @ q2

```
"""
const GateCY = typeof(Control(GateY()))

function decompose!(circ::Circuit, ::GateCY, qtargets, _)
    a, b = qtargets
    push!(circ, GateSDG(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateS(), b)
end

@doc raw"""
    GateCZ()

Two qubit Controlled-``Z`` gate.

!!! details
    Implemented as an alias to `Control(1, GateZ())`.

!!! note
    By convention we refer to the first qubit as the control qubit and the
    second qubit as the target.

## Matrix representation

```math
\operatorname{CZ} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & -1
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCZ(), numcontrols(GateCZ()), numtargets(GateCZ())
(CZ, 1, 1)

julia> matrix(GateCZ())
4×4 Matrix{Float64}:
 1.0  0.0  0.0   0.0
 0.0  1.0  0.0   0.0
 0.0  0.0  1.0   0.0
 0.0  0.0  0.0  -1.0

julia> c = push!(Circuit(), GateCZ(), 1, 2)
2-qubit circuit with 1 instructions:
└── CZ @ q1, q2

julia> power(GateCZ(), 2), inverse(GateCZ())
(CID, CZ)

```

## Decomposition

```jldoctests
julia> decompose(GateCZ())
2-qubit circuit with 3 instructions:
├── H @ q2
├── CX @ q1, q2
└── H @ q2
```
"""
const GateCZ = typeof(Control(GateZ()))

function decompose!(circ::Circuit, ::GateCZ, qtargets, _)
    a, b = qtargets
    push!(circ, GateH(), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateH(), b)
end
