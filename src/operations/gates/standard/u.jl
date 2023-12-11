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
    GateU(θ, ϕ, λ)

Single qubit generic unitary gate ``U(\theta, \phi, \lambda)``, where
``\theta``, ``\phi``, and ``\lambda`` are the Euler angles specified in
radians.

See also [`GateU3`](@ref), [`GateP`](@ref), [`GateU2`](@ref), [`GateU1`](@ref)

## Matrix representation

```math
\operatorname{U}(\theta, \phi, \lambda) = 
        \frac{1}{2}
        \begin{pmatrix}
        1 + e^{i\theta} & -i e^{i\lambda}(1 - e^{i\theta}) \\
        i e^{i\phi}(1 - e^{i\theta}) & e^{i(\phi + \lambda)}(1 + e^{i\theta})
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ ϕ λ
3-element Vector{Symbolics.Num}:
 θ
 ϕ
 λ

julia> GateU(θ, ϕ, λ)
U(θ, ϕ, λ)

julia> matrix(GateU(2.023, 0.5, 0.1))
2×2 Matrix{ComplexF64}:
  0.281526+0.449743im  -0.375769-0.759784im
 0.0502318+0.846139im  -0.021591+0.53015im

julia> c = push!(Circuit(), GateU(θ, ϕ, λ), 1)
1-qubit circuit with 1 instructions:
└── U(θ, ϕ, λ) @ q[1]

julia> push!(c, GateU(π/8, π/2, π/4), 2)
2-qubit circuit with 2 instructions:
├── U(θ, ϕ, λ) @ q[1]
└── U(π/8, π/2, π/4) @ q[2]

julia> power(GateU(θ, ϕ, λ), 2), inverse(GateU(θ, ϕ, λ))
(U(θ, ϕ, λ)^2, U(-θ, -λ, -ϕ))

```

## Decomposition

Since, up to a global phase, the ``U`` matrix, is the most general single qubit unitary matrix,
all other matrices are defined from it.

```jldoctests; setup = :(@variables λ θ ϕ)
julia> decompose(GateU(θ, λ, ϕ))
1-qubit circuit with 1 instructions:
└── U(θ, λ, ϕ) @ q[1]

```
"""
struct GateU <: AbstractGate{1}
    θ::Num
    ϕ::Num
    λ::Num
end

inverse(g::GateU) = GateU(-g.θ, -g.λ, -g.ϕ)

opname(::Type{GateU}) = "U"

_matrix(::Type{GateU}, θ, ϕ, λ) = umatrix(θ, ϕ, λ)


@doc raw"""
    GateUPhase(θ, ϕ, λ, γ)

Single qubit generic unitary gate ``U(\theta, \phi, \lambda, \gamma)``, where
``\theta``, ``\phi``, and ``\lambda`` are the Euler angles specified in
radians, and ``\gamma`` is a global phase.

See also [`GateU`](@ref), [`GPhase`](@ref)

## Matrix representation

```math
\operatorname{U}(\theta, \phi, \lambda, \gamma) = \frac{1}{2} e^{i\gamma} \begin{pmatrix}
        1 + e^{i\theta} & -i e^{i\lambda}(1 - e^{i\theta}) \\
        i e^{i\phi}(1 - e^{i\theta}) & e^{i(\phi + \lambda)}(1 + e^{i\theta})
        \end{pmatrix}
```

## Examples

```jldoctests
julia> @variables θ ϕ λ γ
4-element Vector{Symbolics.Num}:
 θ
 ϕ
 λ
 γ

julia> GateUPhase(θ, ϕ, λ, γ)
U(θ, ϕ, λ, γ)

julia> matrix(GateUPhase(2.023, 0.5, 0.1, 0.2))
2×2 Matrix{ComplexF64}:
  0.186564+0.496709im  -0.217332-0.819293im
 -0.118871+0.839252im  -0.126485+0.515293im

julia> c = push!(Circuit(), GateUPhase(θ, ϕ, λ, γ), 1)
1-qubit circuit with 1 instructions:
└── U(θ, ϕ, λ, γ) @ q[1]

julia> push!(c, GateUPhase(π/8, π/2, π/4, π/7), 2)
2-qubit circuit with 2 instructions:
├── U(θ, ϕ, λ, γ) @ q[1]
└── U(π/8, π/2, π/4, π/7) @ q[2]

julia> power(GateUPhase(θ, ϕ, λ, γ), 2), inverse(GateUPhase(θ, ϕ, λ, γ))
(U(θ, ϕ, λ, γ)^2, U(-θ, -λ, -ϕ, -γ))

```

## Decomposition

Since, up to a global phase, the ``U`` matrix, is the most general single qubit unitary matrix,
all other matrices are defined from it.

```jldoctests; setup = :(@variables λ θ ϕ γ)
julia> decompose(GateUPhase(θ, λ, ϕ, γ))
1-qubit circuit with 2 instructions:
├── GPhase(γ) @ q[1]
└── U(θ, λ, ϕ) @ q[1]

```
"""
struct GateUPhase <: AbstractGate{1}
    θ::Num
    ϕ::Num
    λ::Num
    γ::Num
end

inverse(g::GateUPhase) = GateUPhase(-g.θ, -g.λ, -g.ϕ, -g.γ)

opname(::Type{GateUPhase}) = "U"

_matrix(::Type{GateUPhase}, θ, ϕ, λ, γ) = umatrix(θ, ϕ, λ, γ)

function decompose!(circ::Circuit, g::GateUPhase, qtargets, _)
    a = qtargets[1]
    push!(circ, GPhase(1, g.γ), a)
    push!(circ, GateU(g.θ, g.ϕ, g.λ), a)
    return circ
end
