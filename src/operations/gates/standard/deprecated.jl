#
# Copyright © 2022-2024 University of Strasbourg. All Rights Reserved.
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
    GateU1(λ)

Single qubit rotation `\operatorname{U1}(\lambda)` about the Z axis.

Equivalent to [`GateP`](@ref).

## Matrix representation

```math
\operatorname{U1}(\lambda) =
\begin{pmatrix}
    1 & 0 \\
    0 & e^{i\lambda}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables λ
1-element Vector{Symbolics.Num}:
 λ

julia> GateU1(λ)
U1(λ)

julia> matrix(GateU1(0.519))
2×2 Matrix{ComplexF64}:
 1.0+0.0im       0.0+0.0im
 0.0+0.0im  0.868316+0.496012im

julia> c = push!(Circuit(), GateU1(λ), 1)
1-qubit circuit with 1 instructions:
└── U1(λ) @ q[1]

julia> push!(c, GateU1(π/2), 2)
2-qubit circuit with 2 instructions:
├── U1(λ) @ q[1]
└── U1(π/2) @ q[2]

julia> power(GateU1(λ), 2), inverse(GateU1(λ))
(U1(λ)^2, U1(-λ))

```

## Decomposition

```jldoctests; setup = :(@variables λ)
julia> decompose(GateU1(λ))
1-qubit circuit with 1 instructions:
└── U(0, 0, λ) @ q[1]

```
"""
struct GateU1 <: AbstractGate{1}
    λ::Num
end

inverse(g::GateU1) = GateU1(-g.λ)

opname(::Type{GateU1}) = "U1"

_matrix(::Type{GateU1}, λ) = [1 0; 0 cispi(λ / π)]

function decompose!(circ::Circuit, g::GateU1, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(0, 0, g.λ), q)
    return circ
end

@doc raw"""
    GateU2(ϕ, λ)

Single qubit rotation `\operatorname{U2}(\phi, \lambda)` about the X+Z axis.

## Matrix representation

```math
\operatorname{U2}(\phi,\lambda) = \frac{1}{\sqrt{2}}e^{-(\phi+\lambda)/2}\begin{pmatrix}
1 & -e^{i\lambda} \\
e^{i\phi} & e^{i(\phi+\lambda)}
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables ϕ λ
2-element Vector{Symbolics.Num}:
 ϕ
 λ

julia> GateU2(ϕ, λ)
U2(ϕ, λ)

julia> matrix(GateU2(2.023, 0.5))
2×2 Matrix{ComplexF64}:
  0.707107+0.0im       -0.620545-0.339005im
 -0.308969+0.636033im  -0.576077+0.410044im

julia> c = push!(Circuit(), GateU2(ϕ, λ), 1)
1-qubit circuit with 1 instructions:
└── U2(ϕ, λ) @ q[1]

julia> push!(c, GateU2(π/2, π/4), 2)
2-qubit circuit with 2 instructions:
├── U2(ϕ, λ) @ q[1]
└── U2(π/2, π/4) @ q[2]

julia> power(GateU2(ϕ, λ), 2), inverse(GateU2(ϕ, λ))
(U2(ϕ, λ)^2, U2(-3.141592653589793 - λ, π - ϕ))

```

## Decomposition

```jldoctests; setup = :(@variables ϕ λ)
julia> decompose(GateU2(ϕ, λ))
1-qubit circuit with 1 instructions:
└── U3(π/2, ϕ, λ) @ q[1]

```
"""
struct GateU2 <: AbstractGate{1}
    ϕ::Num
    λ::Num
end

opname(::Type{GateU2}) = "U2"

inverse(g::GateU2) = GateU2(-g.λ - π, -g.ϕ + π)

_matrix(::Type{GateU2}, ϕ, λ) = [1 -cis(λ); cis(ϕ) cis(λ + ϕ)] / sqrt(2)

function decompose!(circ::Circuit, g::GateU2, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU3(π / 2, g.ϕ, g.λ), q)
    return circ
end

@doc raw"""
    GateU3(θ, ϕ, λ)

Single qubit generic unitary gate `U3(\theta, \phi, \lambda)`.

This gate is equivalent to the generic unitary gate [`GateU`](@ref), differing
from it only by a global phase of ``\frac{\phi + \lambda + \theta}{2}``.

## Matrix representation

```math
\operatorname{U3}(\theta,\phi,\lambda) =
\begin{pmatrix}
    \cos\left(\frac{\theta}{2}\right) & -e^{i\lambda}\sin\left(\frac{\theta}{2}\right) \\
    \mathrm{e}^{i\phi}\sin\left(\frac{\theta}{2}\right) & \mathrm{e}^{i(\phi+\lambda)}\cos\left(\frac{\theta}{2}\right)
\end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ ϕ λ
3-element Vector{Symbolics.Num}:
 θ
 ϕ
 λ

julia> GateU3(θ, ϕ, λ)
U3(θ, ϕ, λ)

julia> matrix(GateU3(2.023, 0.5, 0.1))
2×2 Matrix{ComplexF64}:
  0.53059+0.0im       -0.843394-0.0846217im
 0.743864+0.406375im   0.437915+0.299594im

julia> c = push!(Circuit(), GateU3(θ, ϕ, λ), 1)
1-qubit circuit with 1 instructions:
└── U3(θ, ϕ, λ) @ q[1]

julia> push!(c, GateU3(π/8, π/2, π/4), 2)
2-qubit circuit with 2 instructions:
├── U3(θ, ϕ, λ) @ q[1]
└── U3(π/8, π/2, π/4) @ q[2]

julia> power(GateU3(θ, ϕ, λ), 2), inverse(GateU3(θ, ϕ, λ))
(U3(θ, ϕ, λ)^2, U3(-θ, -λ, -ϕ))

```

## Decomposition

```jldoctests; setup = :(@variables θ ϕ λ)
julia> decompose(GateU3(θ, ϕ, λ))
1-qubit circuit with 1 instructions:
└── U(θ, ϕ, λ) @ q[1]

```
"""
struct GateU3 <: AbstractGate{1}
    θ::Num
    ϕ::Num
    λ::Num
end

inverse(g::GateU3) = GateU3(-g.θ, -g.λ, -g.ϕ)

numparams(::Type{GateU3}) = 3

opname(::Type{GateU3}) = "U3"

_matrix(::Type{GateU3}, θ, ϕ, λ) = [cos(θ / 2) -cis(λ)*sin(θ / 2); cis(ϕ)*sin(θ / 2) cis(λ + ϕ)*cos(θ / 2)]

function decompose!(circ::Circuit, g::GateU3, qtargets, _)
    q = qtargets[1]
    push!(circ, GateU(g.θ, g.ϕ, g.λ), q)
    return circ
end
