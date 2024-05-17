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
    GateU(θ, ϕ, λ[, γ = 0])

Single qubit generic unitary gate ``U(\theta, \phi, \lambda, \gamma = 0)``, where
``\theta``, ``\phi``, and ``\lambda`` are the Euler angles specified in
radians, and ``\gamma`` is a global phase.

See also [`GateU3`](@ref), [`GateP`](@ref), [`GateU2`](@ref), [`GateU1`](@ref)

## Matrix representation

```math
\operatorname{U}(\theta, \phi, \lambda, \gamma = 0) =
\mathrm{e}^{i\gamma}
\begin{pmatrix}
    \cos\left(\frac{\theta}{2}\right) & -\mathrm{e}^{i\lambda}\sin\left(\frac{\theta}{2}\right) \\
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

Since ``U`` gate, is the most general single qubit unitary matrix, all other matrices are defined from it.

```jldoctests; setup = :(@variables λ θ ϕ γ)
julia> decompose(GateU(θ, λ, ϕ))
1-qubit circuit with 1 instructions:
└── U(θ, λ, ϕ, γ) @ q[1]

```
"""
struct GateU <: AbstractGate{1}
    θ::Num
    ϕ::Num
    λ::Num
    γ::Num

    function GateU(θ, ϕ, λ, γ=0.0)
        new(θ, ϕ, λ, γ)
    end
end

inverse(g::GateU) = GateU(-g.θ, -g.λ, -g.ϕ, -g.γ)

opname(::Type{GateU}) = "U"

_matrix(::Type{GateU}, θ, ϕ, λ, γ) = umatrix(θ, ϕ, λ, γ)

function _power(g::GateU, pwr)
    Up = matrix(g)^pwr

    γ = angle(Up[1, 1])
    θ = 2 * acos(abs(Up[1, 1]))
    ϕ = angle(Up[2, 1] / sin(θ / 2)) - γ
    λ = angle(-Up[1, 2] / sin(θ / 2)) - γ

    return GateU(θ, ϕ, λ, γ)
end

function Base.show(io::IO, gate::GateU)
    compact = get(io, :compact, false)
    sep = compact ? "," : ", "
    print(io, opname(gate))
    print(io, "(")
    print(io, _displaypi(gate.θ), sep, _displaypi(gate.ϕ), sep, _displaypi(gate.λ))
    if !(Symbolics.value(gate.γ) isa Real) || gate.γ != 0
        print(io, sep, _displaypi(gate.γ))
    end
    print(io, ")")
end

