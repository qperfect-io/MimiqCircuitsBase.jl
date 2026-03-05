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
    ToZRotationRewrite <: RewriteRule

Rewrite rule that converts `GateRX` and `GateRY` rotations into `GateRZ`
conjugated by Clifford gates.

This is useful for backends that natively support only Z-rotations, or as a
preprocessing step before applying [`SpecialAngleRewrite`](@ref) or
[`SolovayKitaevRewrite`](@ref).

# Transformations

| Operation | Decomposition |
|-----------|---------------|
| `RX(θ)` | `H · RZ(θ) · H` |
| `RY(θ)` | `S · H · RZ(θ) · H · Sdg` |

# Examples
```julia
# RX becomes RZ conjugated by Hadamards
decompose_step(GateRX(θ); rule=ToZRotationRewrite())
# Result: H, RZ(θ), H

# RY requires additional S gates
decompose_step(GateRY(θ); rule=ToZRotationRewrite())
# Result: S, H, RZ(θ), H, Sdg
```

See also [`RewriteRule`](@ref), [`SpecialAngleRewrite`](@ref), [`ZYZRewrite`](@ref).
"""
struct ToZRotationRewrite <: RewriteRule end

# --- matches ---

matches(::ToZRotationRewrite, ::GateRX) = true
matches(::ToZRotationRewrite, ::GateRY) = true

# --- decompose_step! ---

function decompose_step!(builder, ::ToZRotationRewrite, g::GateRX, qtargets, _, _)
    # RX(θ) = H · RZ(θ) · H
    q = qtargets[1]
    push!(builder, GateH(), q)
    push!(builder, GateRZ(g.θ), q)
    push!(builder, GateH(), q)
    return builder
end

function decompose_step!(builder, ::ToZRotationRewrite, g::GateRY, qtargets, _, _)
    # RY(θ) = S · H · RZ(θ) · H · Sdg
    q = qtargets[1]
    push!(builder, GateSDG(), q)
    push!(builder, GateH(), q)
    push!(builder, GateRZ(g.θ), q)
    push!(builder, GateH(), q)
    push!(builder, GateS(), q)
    return builder
end
