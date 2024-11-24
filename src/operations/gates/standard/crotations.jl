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
    GateCRX(θ)

Controlled-``\operatorname{R}_X(\theta)`` gate.

!!! details
    Implemented as an alias to `Control(GateRX(θ))`.

See also [`Control`](@ref), [`GateRX`](@ref).

## Matrix representation

```math
\operatorname{CRX}(\theta) = \begin{pmatrix}
            1 & 0 & 0 & 0 \\
            0 & 1 & 0 & 0 \\
            0 & 0 & \cos\frac{\theta}{2} & -i\sin\frac{\theta}{2} \\
            0 & 0 & -i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateCRX(θ), numcontrols(GateCRX(θ)), numtargets(GateCRX(θ))
(GateCRX(θ), 1, 1)

julia> matrix(GateCRX(1.989))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.544922+0.0im            0.0-0.838487im
 0.0+0.0im  0.0+0.0im       0.0-0.838487im  0.544922+0.0im

julia> c = push!(Circuit(), GateCRX(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── CRX(θ) @ q[1], q[2]

julia> push!(c, GateCRX(π/8), 1, 2)
2-qubit circuit with 2 instructions:
├── CRX(θ) @ q[1], q[2]
└── CRX(π/8) @ q[1], q[2]

julia> power(GateCRX(θ), 2), inverse(GateCRX(θ))
(GateCRX(2θ), GateCRX(-θ))

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateCRX(θ))
2-qubit circuit with 5 instructions:
├── P(π/2) @ q[2]
├── CX @ q[1], q[2]
├── U((-1//2)*θ,0,0) @ q[2]
├── CX @ q[1], q[2]
└── U((1//2)*θ,-1π/2,0) @ q[2]

```
"""
const GateCRX = typeof(Control(GateRX(π)))

@definename GateCRX "CRX"

function decompose!(circ::Circuit, g::GateCRX, qtargets, _, _)
    a, b = qtargets
    θ = g.op.θ
    push!(circ, GateP(π / 2), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateU(-θ / 2, 0, 0), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateU(θ / 2, -π / 2, 0), b)
    return circ
end

@doc raw"""
    GateCRY(θ)

Controlled-``\operatorname{R}_Y(\theta)`` gate.

!!! details
    Implemented as an alias to `Control(GateRY(θ))`.

See also [`Control`](@ref), [`GateRY`](@ref).

## Matrix representation

```math
\operatorname{CRY}(\theta) = \begin{pmatrix}
            1 & 0 & 0 & 0 \\
            0 & 1 & 0 & 0 \\
            0 & 0 & \cos\frac{\theta}{2} & -\sin\frac{\theta}{2} \\
            0 & 0 &  \sin\frac{\theta}{2} & \cos\frac{\theta}{2}
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateCRY(θ), numcontrols(GateCRY(θ)), numtargets(GateCRY(θ))
(Control(GateRY(θ)), 1, 1)

julia> matrix(GateCRY(1.989))
4×4 Matrix{Float64}:
 1.0  0.0  0.0        0.0
 0.0  1.0  0.0        0.0
 0.0  0.0  0.544922  -0.838487
 0.0  0.0  0.838487   0.544922

julia> c = push!(Circuit(), GateCRY(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── CRY(θ) @ q[1], q[2]

julia> push!(c, GateCRY(π/8), 1, 2)
2-qubit circuit with 2 instructions:
├── CRY(θ) @ q[1], q[2]
└── CRY(π/8) @ q[1], q[2]

julia> power(GateCRY(θ), 2), inverse(GateCRY(θ))
(Control(GateRY(2θ)), Control(GateRY(-θ)))

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateCRY(θ))
2-qubit circuit with 4 instructions:
├── RY((1//2)*θ) @ q[2]
├── CX @ q[1], q[2]
├── RY((-1//2)*θ) @ q[2]
└── CX @ q[1], q[2]

```
"""
const GateCRY = typeof(Control(GateRY(π)))

function decompose!(circ::Circuit, g::GateCRY, qtargets, _, _)
    a, b = qtargets
    θ = g.op.θ
    push!(circ, GateRY(θ / 2), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRY(-θ / 2), b)
    push!(circ, GateCX(), a, b)
    return circ
end

@doc raw"""
    GateCRZ(θ)

Controlled-``\operatorname{R}_Z(\theta)`` gate.

!!! details
    Implemented as an alias to `Control(GateRZ(θ))`.

See also [`Control`](@ref), [`GateRZ`](@ref).

## Matrix representation

```math
    \operatorname{CRZ}(\theta) = \begin{pmatrix}
            1 & 0 & 0 & 0 \\
            0 & 1 & 0 & 0 \\
            0 & 0 & e^{-i\frac{\lambda}{2}} & 0 \\
            0 & 0 & 0 & e^{i\frac{\lambda}{2}}
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateCRZ(θ), numcontrols(GateCRZ(θ)), numtargets(GateCRZ(θ))
(Control(GateRZ(θ)), 1, 1)

julia> matrix(GateCRZ(1.989))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im            0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.544922-0.838487im       0.0+0.0im
 0.0+0.0im  0.0+0.0im       0.0+0.0im       0.544922+0.838487im

julia> c = push!(Circuit(), GateCRZ(θ), 1, 2)
2-qubit circuit with 1 instructions:
└── CRZ(θ) @ q[1], q[2]

julia> push!(c, GateCRZ(π/8), 1, 2)
2-qubit circuit with 2 instructions:
├── CRZ(θ) @ q[1], q[2]
└── CRZ(π/8) @ q[1], q[2]

julia> power(GateCRZ(θ), 2), inverse(GateCRZ(θ))
(Control(GateRZ(2θ)), Control(GateRZ(-θ)))

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateCRZ(θ))
2-qubit circuit with 4 instructions:
├── RZ((1//2)*θ) @ q[2]
├── CX @ q[1], q[2]
├── RZ((-1//2)*θ) @ q[2]
└── CX @ q[1], q[2]

```
"""
const GateCRZ = typeof(Control(GateRZ(π)))

function decompose!(circ::Circuit, g::GateCRZ, qtargets, _, _)
    a, b = qtargets
    λ = g.op.λ
    push!(circ, GateRZ(λ / 2), b)
    push!(circ, GateCX(), a, b)
    push!(circ, GateRZ(-λ / 2), b)
    push!(circ, GateCX(), a, b)
    return circ
end

