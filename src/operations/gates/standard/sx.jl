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
    GateSX()

Single qubit ``\sqrt{X}`` gate.

See also [`GateSXDG`](@ref), [`GateX`](@ref), [`Power`](@ref)

## Matrix representation

```math
\operatorname{SX} =
\sqrt{\operatorname{X}} =
\frac{1}{2}
\begin{pmatrix}
    1+i & 1-i \\
    1-i & 1+i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSX()
SX

julia> matrix(GateSX())
2×2 Matrix{ComplexF64}:
 0.5+0.5im  0.5-0.5im
 0.5-0.5im  0.5+0.5im

julia> c = push!(Circuit(), GateSX(), 1)
1-qubit circuit with 1 instructions:
└── SX @ q[1]

julia> push!(c, GateSX, 2)
2-qubit circuit with 2 instructions:
├── SX @ q[1]
└── SX @ q[2]

julia> power(GateSX(), 2), inverse(GateSX())
(X, SX†)

```

## Decomposition

```jldoctests
julia> decompose(GateSX())
1-qubit circuit with 4 instructions:
├── S† @ q[1]
├── H @ q[1]
├── S† @ q[1]
└── U(0, 0, 0, π/4) @ q[1]
```
"""
const GateSX = typeof(power(GateX(), 1 // 2))

@definename GateSX "SX"

function decompose!(circ::Circuit, ::GateSX, qtargets, _)
    a = qtargets[1]
    push!(circ, GateSDG(), a)
    push!(circ, GateH(), a)
    push!(circ, GateSDG(), a)
    push!(circ, GateU(0, 0, 0, π / 4), a)
    return circ
end

@doc raw"""
    GateSXDG()

Single qubit ``\sqrt{X}^\dagger`` gate (conjugate transpose of the ``\sqrt{X}``
gate)

See also [`GateSX`](@ref), [`GateX`](@ref), [`Power`](@ref), [`Inverse`](@ref)

## Matrix representation

```math
\operatorname{SXDG} =
\sqrt{\operatorname{X}}^\dagger =
\frac{1}{2}
\begin{pmatrix}
    1-i & 1+i \\
    1+i & 1-i
\end{pmatrix}
```

## Examples

```jldoctests
julia> GateSXDG()
SX†

julia> matrix(GateSXDG())
2×2 adjoint(::Matrix{ComplexF64}) with eltype ComplexF64:
 0.5-0.5im  0.5+0.5im
 0.5+0.5im  0.5-0.5im

julia> c = push!(Circuit(), GateSXDG(), 1)
1-qubit circuit with 1 instructions:
└── SX† @ q[1]

julia> push!(c, GateSXDG, 2)
2-qubit circuit with 2 instructions:
├── SX† @ q[1]
└── SX† @ q[2]

julia> power(GateSXDG(), 2), inverse(GateSXDG())
((SX†)^2, SX)

```
"""
const GateSXDG = typeof(inverse(GateSX()))

function decompose!(circ::Circuit, ::GateSXDG, qtargets, _)
    a = qtargets[1]
    push!(circ, GateS(), a)
    push!(circ, GateH(), a)
    push!(circ, GateS(), a)
    push!(circ, GateU(0, 0, 0, -π / 4), a)
    return circ
end
