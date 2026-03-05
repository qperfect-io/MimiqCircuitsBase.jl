#
# Copyright © 2023-2025 QPerfect. All Rights Reserved.
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

"""
    ZYZRewrite <: RewriteRule

Rewrite rule that decomposes single-qubit unitaries into the ZYZ Euler angle
decomposition: `RZ(α) · RY(β) · RZ(γ)`.

This is a standard decomposition for arbitrary single-qubit gates, producing
only Z and Y rotations (plus a global phase for `GateU`).

# Transformations

| Operation | Decomposition |
|-----------|---------------|
| `GateU(θ, ϕ, λ, γ)` | `RZ(λ) · RY(θ) · RZ(ϕ) · Phase(γ)` |
| `GateRX(θ)` | `S · RY(θ) · Sdg` |

Identity rotations (angle = 0) are omitted from the output.

# Examples
```julia
# U gate decomposes to RZ-RY-RZ sequence
decompose_step(GateU(π/2, π/4, π/3); rule=ZYZRewrite())

# RX is converted via S conjugation
decompose_step(GateRX(θ); rule=ZYZRewrite())
# Result: S, RY(θ), Sdg
```

See also [`RewriteRule`](@ref), [`ToZRotationRewrite`](@ref), [`SpecialAngleRewrite`](@ref).
"""
struct ZYZRewrite <: RewriteRule end

# --- matches --- 

# Match GateU unless it's the identity (all angles zero)
function matches(::ZYZRewrite, g::GateU)
    return !iszero(getparam(g, :θ)) ||
           !iszero(getparam(g, :ϕ)) ||
           !iszero(getparam(g, :λ))
end

matches(::ZYZRewrite, ::GateRX) = true

# --- decompose_step! --- 

function decompose_step!(builder, ::ZYZRewrite, g::GateU, qtargets, _, _)
    # GateU(θ, ϕ, λ, γ) = e^{iγ} · RZ(ϕ) · RY(θ) · RZ(λ)
    # We emit gates right-to-left (matrix multiplication order):
    #   RZ(λ), then RY(θ), then RZ(ϕ), then global phase

    q = qtargets[1]

    λ = getparam(g, :λ)
    θ = getparam(g, :θ)
    ϕ = getparam(g, :ϕ)
    γ = getparam(g, :γ)

    !iszero(λ) && push!(builder, GateRZ(λ), q)
    !iszero(θ) && push!(builder, GateRY(θ), q)
    !iszero(ϕ) && push!(builder, GateRZ(ϕ), q)
    !iszero(γ) && push!(builder, GateU(0, 0, 0, γ), q)

    return builder
end

function decompose_step!(builder, ::ZYZRewrite, g::GateRX, qtargets, _, _)
    # RX(θ) = S · RY(θ) · Sdg
    # This converts X-rotation to Y-rotation via S conjugation,
    # keeping all rotations in the Y-Z plane.

    q = qtargets[1]

    push!(builder, GateS(), q)
    push!(builder, GateRY(g.θ), q)
    push!(builder, GateSDG(), q)

    return builder
end
