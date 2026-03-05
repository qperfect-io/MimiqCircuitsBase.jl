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

# --- RewriteRule — single-step transformations ---

"""
    RewriteRule

Abstract type for single-step rewrite rules that transform one operation into
a sequence of simpler operations.

A `RewriteRule` defines *how* to transform an operation, but not *when* to stop.
For recursive decomposition to a target set of operations, see [`DecompositionBasis`](@ref).

# Interface

Subtypes must implement:

- [`matches(rule, op)`](@ref): Return `true` if this rule can transform `op`.
- [`decompose_step!(builder, rule, op, qtargets, ctargets, ztargets)`](@ref): 
  Append the transformed instructions to `builder`.

# Examples
```julia
struct MyRewrite <: RewriteRule end

matches(::MyRewrite, ::GateToffoli) = true
matches(::MyRewrite, ::Operation) = false

function decompose_step!(builder, ::MyRewrite, op::GateToffoli, qt, ct, zt)
    # ... append decomposed instructions to builder
    return builder
end
```

See also [`CanonicalRewrite`](@ref), [`DecompositionBasis`](@ref).
"""
abstract type RewriteRule end

"""
    matches(rule::RewriteRule, op::Operation) -> Bool

Return `true` if `rule` can transform operation `op`.

This is used to check whether a rewrite rule is applicable before attempting
decomposition.

# Examples
```julia
matches(CanonicalRewrite(), GateH())  # true if CanonicalRewrite handles GateH
```

See also [`RewriteRule`](@ref), [`decompose_step!`](@ref).
"""
matches(::RewriteRule, ::Operation) = false

"""
    decompose_step!(builder, rule::RewriteRule, op::Operation, qtargets, ctargets, ztargets)

Apply `rule` to transform `op` and append the resulting instructions to `builder`.

This is the low-level interface that each [`RewriteRule`](@ref) must implement
for operations it [`matches`](@ref).

# Arguments

- `builder`: A circuit-like container (e.g., `Circuit`, `Vector{Instruction}`) to append to.
- `rule`: The rewrite rule to apply.
- `op`: The operation to transform.
- `qtargets`: Qubit indices for the operation.
- `ctargets`: Classical bit indices for the operation.
- `ztargets`: Z-variable indices for the operation.

# Returns

The `builder` with decomposed instructions appended.

See also [`RewriteRule`](@ref), [`matches`](@ref), [`decompose_step`](@ref).
"""
function decompose_step!(builder, rule::RewriteRule, op::Operation, qtargets, ctargets, ztargets)
    if matches(rule, op)
        # Programmer error: matches returns true but decompose_step! not implemented
        throw(ErrorException(
            "decompose_step! must be implemented for $(typeof(rule)) to decompose $(typeof(op))."
        ))
    end
    throw(DecompositionError(
        "Operation $(opname(op)) cannot be decomposed by $(typeof(rule))."
    ))
end

# --- DecompositionBasis — recursive decomposition to a target set ---

"""
    DecompositionBasis

Abstract type for decomposition targets that define a set of terminal operations
and how to decompose non-terminal operations.

A `DecompositionBasis` combines two concerns:

1. **What is terminal**: Operations that should not be decomposed further.
2. **How to decompose**: The transformation logic for non-terminal operations.

# Interface

Subtypes must implement:

- [`isterminal(basis, op)`](@ref): Return `true` if `op` is in the target set.
- [`decompose!(builder, basis, op, qtargets, ctargets, ztargets)`](@ref): 
  Append decomposed instructions to `builder` for non-terminal operations.

# Examples

```julia
struct CliffordT <: DecompositionBasis end

# Define terminal operations
isterminal(::CliffordT, ::GateH) = true
isterminal(::CliffordT, ::GateS) = true
isterminal(::CliffordT, ::GateT) = true
isterminal(::CliffordT, ::GateCX) = true
isterminal(::CliffordT, ::Operation) = false

# Define decomposition (can delegate to rewrite rules)
function decompose!(builder, ::CliffordT, op::Operation, qt, ct, zt)
    return decompose_step!(builder, CanonicalRewrite(), op, qt, ct, zt)
end
```

See also [`CanonicalBasis`](@ref), [`RewriteRule`](@ref), [`decompose`](@ref).
"""
abstract type DecompositionBasis end

"""
    isterminal(basis::DecompositionBasis, op::Operation) -> Bool

Return `true` if `op` is terminal in the given `basis`.

Terminal operations are not decomposed further—they represent the target
instruction set that [`decompose`](@ref) reduces circuits to.

# Examples

```julia
isterminal(CanonicalBasis(), GateU())   # true
isterminal(CanonicalBasis(), GateH())   # false (will be decomposed)
```

See also [`DecompositionBasis`](@ref), [`decompose`](@ref).
"""
isterminal(::DecompositionBasis, ::Operation) = false
