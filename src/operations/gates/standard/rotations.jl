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
    GateRX(θ)

Single qubit parametric rotation ``\operatorname{R}_X(\theta)`` gate.

It performs a rotation of ``\theta`` radians around the X-axis of the Bloch
sphere of the target qubit.

## Matrix representation

```math
\operatorname{R}_X(\theta) =
\begin{pmatrix}
    \cos\frac{\theta}{2} & -i\sin\frac{\theta}{2} \\
    -i\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRX(θ)
RX(θ)

julia> matrix(GateRX(1.989))
2×2 Matrix{ComplexF64}:
    0.544922+0.0im       -5.55112e-17-0.838487im
 5.55112e-17-0.838487im      0.544922+0.0im

julia> c = push!(Circuit(), GateRX(θ), 1)
1-qubit circuit with 1 instructions:
└── RX(θ) @ q[1]

julia> push!(c, GateRX(π/2), 2)
2-qubit circuit with 2 instructions:
├── RX(θ) @ q[1]
└── RX(π/2) @ q[2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRX(θ))
1-qubit circuit with 2 instructions:
├── U(θ, -1π/2, π/2) @ q[1]
└── GPhase((-1//2)*θ) @ q[1]

```
"""
struct GateRX <: AbstractGate{1}
    θ::Num
end

opname(::Type{GateRX}) = "RX"

inverse(g::GateRX) = GateRX(-g.θ)

_matrix(::Type{GateRX}, θ) = gphase(-θ / 2) * umatrix(θ, -π / 2, π / 2)

_power(g::GateRX, pwr) = GateRX(g.θ * pwr)

function decompose!(circ::Circuit, g::GateRX, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(g.θ, -π / 2, π / 2), q)
    push!(circ, GPhase(1, -g.θ / 2), q)
    return circ
end

@doc raw"""
    GateRY(θ)

Single qubit parametric rotation ``\operatorname{R}_Y(\theta)`` gate.

It performss a rotation of ``\theta`` radians around the Y-axis of the Bloch
sphere of the target qubit.

## Matrix representation

```math
\operatorname{R}_Y(\theta) =
\begin{pmatrix}
    \cos\frac{\theta}{2} & -\sin\frac{\theta}{2} \\
    \sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRY(θ)
RY(θ)

julia> matrix(GateRY(1.989))
2×2 Matrix{ComplexF64}:
 0.544922+0.0im  -0.838487+0.0im
 0.838487+0.0im   0.544922+0.0im

julia> c = push!(Circuit(), GateRY(θ), 1)
1-qubit circuit with 1 instructions:
└── RY(θ) @ q[1]

julia> push!(c, GateRY(π/2), 2)
2-qubit circuit with 2 instructions:
├── RY(θ) @ q[1]
└── RY(π/2) @ q[2]

```

## Decomposition

```jldoctests; setup=:(@variables θ)
julia> decompose(GateRY(θ))
1-qubit circuit with 2 instructions:
├── U(θ, 0, 0) @ q[1]
└── GPhase((-1//2)*θ) @ q[1]

```
"""
struct GateRY <: AbstractGate{1}
    θ::Num
end

inverse(g::GateRY) = GateRY(-g.θ)

opname(::Type{GateRY}) = "RY"

_matrix(::Type{GateRY}, θ) = gphase(-θ / 2) * umatrix(θ, 0, 0)

_power(g::GateRY, pwr) = GateRY(g.θ * pwr)

function decompose!(circ::Circuit, g::GateRY, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(g.θ, 0, 0), q)
    push!(circ, GPhase(1, -g.θ / 2), q)
    return circ
end

@doc raw"""
    GateRZ(λ)

Single qubit parametric rotation ``\operatorname{R}_Z(\lambda)`` gate.

It performs a rotation of ``\lambda`` radians around the Z-axis of the Bloch
sphere for the target qubit.

## Matrix representation

```math
\operatorname{RZ}(\lambda) =
\begin{pmatrix}
    e^{-i\frac{\lambda}{2}} & 0 \\
    0 & e^{i\frac{\lambda}{2}}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ
1-element Vector{Symbolics.Num}:
 θ

julia> GateRZ(θ)
RZ(θ)

julia> matrix(GateRZ(1.989))
2×2 Matrix{ComplexF64}:
 0.544922-0.838487im       0.0+0.0im
      0.0+0.0im       0.544922+0.838487im

julia> c = push!(Circuit(), GateRZ(θ), 1)
1-qubit circuit with 1 instructions:
└── RZ(θ) @ q[1]

julia> push!(c, GateRZ(π/2), 2)
2-qubit circuit with 2 instructions:
├── RZ(θ) @ q[1]
└── RZ(π/2) @ q[2]

```

## Decomposition

```jldoctests; setup = :(@variables θ)
julia> decompose(GateRZ(θ))
1-qubit circuit with 2 instructions:
├── U(0, 0, θ) @ q[1]
└── GPhase((-1//2)*θ) @ q[1]

```
"""
struct GateRZ <: AbstractGate{1}
    λ::Num
end

inverse(g::GateRZ) = GateRZ(-g.λ)

opname(::Type{GateRZ}) = "RZ"

_matrix(::Type{GateRZ}, λ) = gphase(-λ / 2) * umatrix(0, 0, λ)

_power(g::GateRZ, pwr) = GateRZ(g.λ * pwr)

function decompose!(circ::Circuit, g::GateRZ, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, g.λ), q)
    push!(circ, GPhase(1, -g.λ / 2), q)
    return circ
end

@doc raw"""
    GateR(θ, ϕ)

Single qubit parametric rotation ``\operatorname{R}(\theta, \lambda)`` gate.

It performs a rotation of ``\theta`` radians for the target qubit around an
XY-plane axis of the Bloch sphere determined by
``\cos(\phi)\mathbf{x} + \sin(\phi)\mathbf{y}``.

## Matrix representation

```math
\operatorname{R}(\theta,\phi) =
\begin{pmatrix}
    \cos\frac{\theta}{2} & -ie^{-i\phi}\sin\frac{\theta}{2} \\
    -ie^{-i\phi}\sin\frac{\theta}{2} & \cos\frac{\theta}{2}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ ϕ
2-element Vector{Symbolics.Num}:
 θ
 ϕ

julia> GateR(θ, ϕ)
R(θ, ϕ)

julia> matrix(GateR(2.023, 1.989))
2×2 Matrix{ComplexF64}:
 0.53059-2.77556e-17im  -0.77458+0.344239im
 0.77458+0.344239im      0.53059-2.77556e-17im

julia> c = push!(Circuit(), GateR(θ, ϕ), 1)
1-qubit circuit with 1 instructions:
└── R(θ, ϕ) @ q[1]

julia> push!(c, GateR(π/2, π/4), 2)
2-qubit circuit with 2 instructions:
├── R(θ, ϕ) @ q[1]
└── R(π/2, π/4) @ q[2]

```

## Decomposition

```jldoctests; setup = :(@variables θ ϕ)
julia> decompose(GateR(θ, ϕ))
1-qubit circuit with 1 instructions:
└── U3(θ, -1.5707963267948966 + ϕ, 1.5707963267948966 - ϕ) @ q[1]

```
"""
struct GateR <: AbstractGate{1}
    θ::Num
    ϕ::Num
end

inverse(g::GateR) = GateR(-g.θ, g.ϕ)

opname(::Type{GateR}) = "R"

_matrix(::Type{GateR}, θ, ϕ) = _matrix(GateU3, θ, ϕ - π / 2, -ϕ + π / 2)

function decompose!(circ::Circuit, g::GateR, qtargets, _)
    a = qtargets[1]
    push!(circ, GateU3(g.θ, g.ϕ - π / 2, -g.ϕ + π / 2), a)
    return circ
end
