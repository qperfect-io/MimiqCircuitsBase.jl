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
    GateCS()

Two qubit Controlled-S gate.

!!! details
    Implemented as an alias to `Control(1, GateS())`.

See also [`GateS`](@ref), [`Control`](@ref).

## Matrix representation

```math
\operatorname{CS} =\begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCS(), numcontrols(GateCS()), numtargets(GateCS())
(CS, 1, 1)

julia> matrix(GateCS())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+1.0im

julia> c = push!(Circuit(), GateCS(), 1, 2)
2-qubit circuit with 1 instructions:
└── CS @ q[1], q[2]

julia> power(GateCS(), 2), inverse(GateCS())
(CZ, C(S†))

```

## Decomposition

```jldoctests
julia> decompose(GateCS())
2-qubit circuit with 1 instructions:
└── CP(π/2) @ q[1], q[2]

```
"""
const GateCS = typeof(Control(1, GateS()))

function decompose!(circ::Circuit, ::GateCS, qtargets, _)
    a, b = qtargets
    push!(circ, GateCP(π / 2), a, b)
    return circ
end

@doc raw"""
    GateCSDG()

    Adjoint of two qubit Controlled-S gate.

!!! details
    Implemented as an alias to `inverse(Control(1, GateS()))`.

See also [`GateS`](@ref), [`Control`](@ref).

## Matrix representation

```math
\operatorname{CS}^{\dagger} = \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & 1 & 0 \\
    0 & 0 & 0 & -i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateCSDG(), numcontrols(GateCSDG()), numtargets(GateCSDG())
(C(S†), 1, 1)

julia> matrix(GateCSDG())
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  1.0+0.0im  0.0+0.0im  0.0+0.0im
 0.0+0.0im  0.0+0.0im  1.0-0.0im  0.0-0.0im
 0.0+0.0im  0.0+0.0im  0.0-0.0im  0.0-1.0im

julia> c = push!(Circuit(), GateCSDG(), 1, 2)
2-qubit circuit with 1 instructions:
└── C(S†) @ q[1], q[2]

julia> power(GateCSDG(), 2), inverse(GateCSDG())
(C(S†^2), CS)

```

## Decomposition

```jldoctests
julia> decompose(GateCSDG())
2-qubit circuit with 1 instructions:
└── CP(-1π/2) @ q[1], q[2]

```
"""
const GateCSDG = typeof(inverse(Control(1, GateS())))

function decompose!(circ::Circuit, ::GateCSDG, qtargets, _)
    a, b = qtargets
    push!(circ, GateCP(-π / 2), a, b)
    return circ
end
