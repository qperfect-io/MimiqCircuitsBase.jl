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
    ToffoliToCliffordTRewrite <: RewriteRule

Rewrite rule that decomposes the Toffoli gate (`GateCCX`) into Clifford+T gates.

The decomposition uses 7 T/Tdg gates and 6 CNOT gates, which is optimal for
T-count. This is the standard textbook decomposition.

# Transformation
```
CCX(c1, c2, t) → H(t), CX(c2,t), Tdg(t), CX(c1,t), T(t), CX(c2,t), Tdg(t),
                 CX(c1,t), T(c2), T(t), H(t), CX(c1,c2), T(c1), Tdg(c2), CX(c1,c2)
```

# Output Gates

The decomposition produces only:
- `GateH`
- `GateCX`
- `GateT`, `GateTDG`

# Examples
```julia
decompose_step(GateCCX(); rule=ToffoliToCliffordTRewrite())
```

See also [`RewriteRule`](@ref), [`SpecialAngleRewrite`](@ref).
"""
struct ToffoliToCliffordTRewrite <: RewriteRule end

# --- matches ---

matches(::ToffoliToCliffordTRewrite, ::GateCCX) = true
matches(::ToffoliToCliffordTRewrite, ::Operation) = false

# --- decompose_step! ---

function decompose_step!(builder, ::ToffoliToCliffordTRewrite, ::GateCCX, qtargets, _, _)
    c1, c2, t = qtargets

    # Standard Toffoli decomposition (T-count = 7, CNOT-count = 6)

    push!(builder, GateH(), t)
    push!(builder, GateCX(), c2, t)
    push!(builder, GateTDG(), t)
    push!(builder, GateCX(), c1, t)
    push!(builder, GateT(), t)
    push!(builder, GateCX(), c2, t)
    push!(builder, GateTDG(), t)
    push!(builder, GateCX(), c1, t)
    push!(builder, GateT(), c2)
    push!(builder, GateT(), t)
    push!(builder, GateH(), t)
    push!(builder, GateCX(), c1, c2)
    push!(builder, GateT(), c1)
    push!(builder, GateTDG(), c2)
    push!(builder, GateCX(), c1, c2)

    return builder
end
