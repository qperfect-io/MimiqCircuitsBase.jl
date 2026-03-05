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
    SpecialAngleRewrite <: RewriteRule

Rewrite rule that decomposes single-qubit rotations with special angles
into explicit Clifford or Clifford+T gates.

This rule only matches rotations whose angle is a multiple of π/4 (or π/2 in
Clifford-only mode). Generic rotations with arbitrary angles are not matched
and should be handled by other rules (e.g., [`SolovayKitaevRewrite`](@ref)).

# Constructor

    SpecialAngleRewrite(; only_cliffords::Bool=false)

- `only_cliffords=false` (default): Match angles k·π/4, decompose to Clifford+T
- `only_cliffords=true`: Match only angles k·π/2, decompose to Clifford gates only

# Supported Operations

| Operation | Condition | Decomposition |
|-----------|-----------|---------------|
| `GateRX(θ)` | `θ = k⋅π/4` | `X`, `SX`, `H`, `T` sequences |
| `GateRY(θ)` | `θ = k⋅π/4` | `Y`, `SY`, `S`, `H`, `T` sequences |
| `GateRZ(λ)` | `λ = k⋅π/4` | `Z`, `S`, `T` sequences |

When `only_cliffords=true`, only even values of `k` are matched (k=0,2,4,6),
producing only Clifford gates (identity, S/SX/SY, Z/X/Y, S†/SX†/SY†).

# Examples
```julia
# Default: Clifford+T decomposition
rule = SpecialAngleRewrite()
decompose_step(GateRZ(π/4); rule=rule)  # → T

# Clifford-only mode (for Stim compatibility)
rule_clifford = SpecialAngleRewrite(only_cliffords=true)
matches(rule_clifford, GateRZ(π/2))  # true  → S
matches(rule_clifford, GateRZ(π/4))  # false → not matched (T is non-Clifford)

# Generic rotation is not matched
matches(SpecialAngleRewrite(), GateRZ(0.123))  # false
```

See also [`RewriteRule`](@ref), [`CliffordTBasis`](@ref), [`StimBasis`](@ref).
"""
struct SpecialAngleRewrite <: RewriteRule
    only_cliffords::Bool
end

function SpecialAngleRewrite(; only_cliffords::Bool=false)
    return SpecialAngleRewrite(only_cliffords)
end

# --- helper functions ---

"""
    get_pi_factor_or_nothing(val) -> Union{Int, Nothing}

Check if `val` is a multiple of π/4 and return the factor `k ∈ {0,1,...,7}`.

Returns `nothing` if `val` is symbolic or not a multiple of π/4.
"""
function get_pi_factor_or_nothing(val)
    if issymbolic(val)
        return nothing
    end

    # Unwrap Symbolics.Num if it contains a concrete value
    uval = unwrapvalue(val)

    # Check for multiples of π/4: val ≈ k * (π/4)
    factor = uval / (π / 4)
    k = round(Int, factor)
    if isapprox(uval, k * (π / 4); atol=1e-8)
        return mod(k, 8)
    end

    return nothing
end

# --- matches — check for π/4 multiples ---

function matches(rule::SpecialAngleRewrite, g::GateRX)
    k = get_pi_factor_or_nothing(g.θ)
    isnothing(k) && return false
    return !rule.only_cliffords || iseven(k)
end

function matches(rule::SpecialAngleRewrite, g::GateRY)
    k = get_pi_factor_or_nothing(g.θ)
    isnothing(k) && return false
    return !rule.only_cliffords || iseven(k)
end

function matches(rule::SpecialAngleRewrite, g::GateRZ)
    k = get_pi_factor_or_nothing(g.λ)
    isnothing(k) && return false
    return !rule.only_cliffords || iseven(k)
end

# --- decompose_step! — expand to Clifford+T ---

function decompose_step!(builder, ::SpecialAngleRewrite, g::GateRX, qtargets, _, _)
    k = get_pi_factor_or_nothing(g.θ)
    if isnothing(k)
        push!(builder, g, qtargets...)
        return builder
    end

    q = qtargets[1]

    # TX = RX(π/4) = H·T·H
    function push_tx!(b, qt)
        push!(b, GateH(), qt)
        push!(b, GateT(), qt)
        push!(b, GateH(), qt)
    end

    # TXdg = RX(-π/4) = H·Tdg·H
    function push_txdg!(b, qt)
        push!(b, GateH(), qt)
        push!(b, GateTDG(), qt)
        push!(b, GateH(), qt)
    end

    # Decomposition table for RX(k·π/4):
    #   k=0: identity (no-op)
    #   k=1: TX
    #   k=2: SX
    #   k=3: SX·TX
    #   k=4: X
    #   k=5: X·TX
    #   k=6: SXdg
    #   k=7: TXdg
    if k == 0
        # identity
    elseif k == 1
        push_tx!(builder, q)
    elseif k == 2
        push!(builder, GateSX(), q)
    elseif k == 3
        push!(builder, GateSX(), q)
        push_tx!(builder, q)
    elseif k == 4
        push!(builder, GateX(), q)
    elseif k == 5
        push!(builder, GateX(), q)
        push_tx!(builder, q)
    elseif k == 6
        push!(builder, GateSXDG(), q)
    elseif k == 7
        push_txdg!(builder, q)
    end

    return builder
end

function decompose_step!(builder, ::SpecialAngleRewrite, g::GateRY, qtargets, _, _)
    k = get_pi_factor_or_nothing(g.θ)
    if isnothing(k)
        push!(builder, g, qtargets...)
        return builder
    end

    q = qtargets[1]

    # TY = RY(π/4) = S·H·T·H·Sdg
    # Derived from: RY(θ) = Sdg·H·RZ(θ)·H·S, with RZ(π/4) = T
    function push_ty!(b, qt)
        push!(b, GateSDG(), qt)
        push!(b, GateH(), qt)
        push!(b, GateT(), qt)
        push!(b, GateH(), qt)
        push!(b, GateS(), qt)
    end

    # TYdg = RY(-π/4)
    function push_tydg!(b, qt)
        push!(b, GateSDG(), qt)
        push!(b, GateH(), qt)
        push!(b, GateTDG(), qt)
        push!(b, GateH(), qt)
        push!(b, GateS(), qt)
    end

    # Decomposition table for RY(k·π/4):
    #   k=0: identity (no-op)
    #   k=1: TY
    #   k=2: SY
    #   k=3: SY·TY
    #   k=4: Y
    #   k=5: Y·TY
    #   k=6: SYdg
    #   k=7: TYdg
    if k == 0
        # identity
    elseif k == 1
        push_ty!(builder, q)
    elseif k == 2
        push!(builder, GateSY(), q)
    elseif k == 3
        push!(builder, GateSY(), q)
        push_ty!(builder, q)
    elseif k == 4
        push!(builder, GateY(), q)
    elseif k == 5
        push!(builder, GateY(), q)
        push_ty!(builder, q)
    elseif k == 6
        push!(builder, GateSYDG(), q)
    elseif k == 7
        push_tydg!(builder, q)
    end

    return builder
end

function decompose_step!(builder, ::SpecialAngleRewrite, g::GateRZ, qtargets, _, _)
    k = get_pi_factor_or_nothing(g.λ)
    if isnothing(k)
        push!(builder, g, qtargets...)
        return builder
    end

    q = qtargets[1]

    # Decomposition table for RZ(k·π/4):
    #   k=0: identity (no-op)
    #   k=1: T
    #   k=2: S
    #   k=3: S·T
    #   k=4: Z
    #   k=5: Z·T
    #   k=6: Sdg
    #   k=7: Tdg
    if k == 0
        # identity
    elseif k == 1
        push!(builder, GateT(), q)
    elseif k == 2
        push!(builder, GateS(), q)
    elseif k == 3
        push!(builder, GateS(), q)
        push!(builder, GateT(), q)
    elseif k == 4
        push!(builder, GateZ(), q)
    elseif k == 5
        push!(builder, GateZ(), q)
        push!(builder, GateT(), q)
    elseif k == 6
        push!(builder, GateSDG(), q)
    elseif k == 7
        push!(builder, GateTDG(), q)
    end

    return builder
end
