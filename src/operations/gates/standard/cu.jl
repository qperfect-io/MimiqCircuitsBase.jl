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
    GateCU(θ, ϕ, λ)

Controlled-``\operatorname{U}(\theta, \phi, \lambda)`` gate.

!!! details
    Implemented as an alias to `Control(1, GateU(θ, ϕ, λ, γ))`.

See also [`Control`](@ref), [`GateU`](@ref).

```math
\operatorname{CU}(\theta, \phi, \lambda, \gamma) =
\frac{1}{2} \begin{pmatrix}
    1 & 0 & 0 & 0 \\
    0 & 1 & 0 & 0 \\
    0 & 0 & e^{i\gamma} \cos\left(\frac{\theta}{2}\right) & -e^{i\gamma} e^{i\lambda}\sin\left(\frac{\theta}{2}\right) \\
    0 & 0 & e^{i\gamma} \mathrm{e}^{i\phi}\sin\left(\frac{\theta}{2}\right) & e^{i\gamma} \mathrm{e}^{i(\phi+\lambda)}\cos\left(\frac{\theta}{2}\right)
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

julia> GateCU(θ, ϕ, λ, γ), numcontrols(GateCU(θ, ϕ, λ, γ)), numtargets(GateCU(θ, ϕ, λ, γ))
(GateCU(θ, ϕ, λ, γ), 1, 1)

julia> matrix(GateCU(2.023, 0.5, 0.1, 0.2))
4×4 Matrix{ComplexF64}:
 1.0+0.0im  0.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  1.0+0.0im       0.0+0.0im             0.0+0.0im
 0.0+0.0im  0.0+0.0im  0.520013+0.105412im  -0.809771-0.250491im
 0.0+0.0im  0.0+0.0im  0.648302+0.546057im   0.369666+0.380622im

julia> c = push!(Circuit(), GateCU(θ, ϕ, λ, γ), 1, 2)
2-qubit circuit with 1 instructions:
└── CU(θ,ϕ,λ,γ) @ q[1], q[2]

julia> push!(c, GateCU(π/8, π/2, π/4, π/7), 1, 2)
2-qubit circuit with 2 instructions:
├── CU(θ,ϕ,λ,γ) @ q[1], q[2]
└── CU(π/8,π/2,π/4,π/7) @ q[1], q[2]

julia> power(GateCU(θ, ϕ, λ, γ), 2), inverse(GateCU(θ, ϕ, λ, γ))
(Control(GateU(θ, ϕ, λ, γ)^2), GateCU(-θ, -λ, -ϕ, -γ))

```

## Decomposition

```jldoctests; setup = :(@variables λ θ ϕ γ)
julia> decompose(GateCU(θ, λ, ϕ, γ))
2-qubit circuit with 7 instructions:
├── P(γ) @ q[1]
├── P((1//2)*(λ + ϕ)) @ q[1]
├── P((1//2)*(-λ + ϕ)) @ q[2]
├── CX @ q[1], q[2]
├── U((-1//2)*θ,0,(1//2)*(-λ - ϕ)) @ q[2]
├── CX @ q[1], q[2]
└── U((1//2)*θ,λ,0) @ q[2]

```
"""
const GateCU = typeof(Control(1, GateU(π, π, π, π)))

@definename GateCU "CU"

function decompose!(circ::Circuit, g::GateCU, qtargets, _, _)
    c, t = qtargets
    op = getoperation(g)

    θ = op.θ
    ϕ = op.ϕ
    λ = op.λ
    γ = op.γ

    push!(circ, GateP(γ), c)
    push!(circ, GateP((λ + ϕ) / 2), c)
    push!(circ, GateP((λ - ϕ) / 2), t)
    push!(circ, GateCX(), c, t)
    push!(circ, GateU(-θ / 2, 0, -(λ + ϕ) / 2), t)
    push!(circ, GateCX(), c, t)
    push!(circ, GateU(θ / 2, ϕ, 0), t)

    return circ
end
