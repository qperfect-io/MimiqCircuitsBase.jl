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
    GateCU(θ, ϕ, λ)

Controlled-``\operatorname{U}(\theta, \phi, \lambda)`` gate.

!!! details
    Implemented as an alias to `Control(1, GateUPhase(θ, ϕ, λ, γ))`.

See also [`Control`](@ref), [`GateUPhase`](@ref).

## Examples

```jldoctests
julia> @variables θ ϕ λ γ
4-element Vector{Symbolics.Num}:
 θ
 ϕ
 λ
 γ

julia> GateCU(θ, ϕ, λ, γ), numcontrols(GateCU(θ, ϕ, λ, γ)), numtargets(GateCU(θ, ϕ, λ, γ))
(CU(θ, ϕ, λ, γ), 1, 1)

julia> matrix(GateCU(2.023, 0.5, 0.1, 0.2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im        0.0+0.0im             0.0+0.0im
 0.0+0.0im  1.0+0.0im        0.0+0.0im             0.0+0.0im
 0.0+0.0im  0.0+0.0im   0.186564+0.496709im  -0.217332-0.819293im
 0.0+0.0im  0.0+0.0im  -0.118871+0.839252im  -0.126485+0.515293im

julia> c = push!(Circuit(), GateCU(θ, ϕ, λ, γ), 1, 2)
2-qubit circuit with 1 instructions:
└── CU(θ, ϕ, λ, γ) @ q1, q2

julia> push!(c, GateCU(π/8, π/2, π/4, π/7), 1, 2)
2-qubit circuit with 2 instructions:
├── CU(θ, ϕ, λ, γ) @ q1, q2
└── CU(π/8, π/2, π/4, π/7) @ q1, q2

julia> power(GateCU(θ, ϕ, λ, γ), 2), inverse(GateCU(θ, ϕ, λ, γ))
(C(U(θ, ϕ, λ, γ)^2), CU(-θ, -λ, -ϕ, -γ))

```

## Decomposition

```jldoctests; setup = :(@variables λ θ ϕ γ)
julia> decompose(GateCU(θ, λ, ϕ, γ))
2-qubit circuit with 8 instructions:
├── CGPhase(γ) @ q1, q2
├── U((1//2)*θ, 0, ϕ) @ q2
├── CX @ q1, q2
├── U((1//2)*θ, (1//2)*(6.283185307179586 - λ - ϕ), π) @ q2
├── CX @ q1, q2
├── P((1//2)*(λ - ϕ)) @ q2
├── P((1//2)*(θ + λ + ϕ)) @ q1
└── GPhase((-1//2)*θ) @ q[1,2]

```
"""
const GateCU = typeof(Control(1, GateUPhase(π, π, π, π)))

function decompose!(circ::Circuit, g::GateCU, qtargets, _)
    c, t = qtargets
    op = getoperation(g)

    θ = op.θ
    ϕ = op.ϕ
    λ = op.λ
    γ = op.γ

    push!(circ, Control(GPhase(1, γ)), c, t)
    push!(circ, GateU(θ / 2, 0, λ), t)
    push!(circ, GateCX(), c, t)
    push!(circ, GateU(θ / 2, -(λ + ϕ - 2π) / 2, π), t)
    push!(circ, GateCX(), c, t)
    push!(circ, GateP(-(λ - ϕ) / 2), t)
    push!(circ, GateP((λ + ϕ + θ) / 2), c)
    push!(circ, GPhase(2, -θ / 2), c, t)

    return circ
end
