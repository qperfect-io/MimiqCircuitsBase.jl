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
    CanonicalBasis <: DecompositionBasis

The canonical basis decomposes all operations to a minimal set of primitives:
`GateU`, `GateCX`, `Measure`, `Reset`, and other irreducible operations.

This is the default basis used by [`decompose`](@ref).

# Examples
```julia
decompose(circuit) # uses CanonicalBasis() by default
decompose(circuit; basis=CanonicalBasis())
```

See also [`DecompositionBasis`](@ref), [`CanonicalRewrite`](@ref).
"""
struct CanonicalBasis <: DecompositionBasis end

# --- terminal operations ---

# Core gates
isterminal(::CanonicalBasis, ::GateU) = true
isterminal(::CanonicalBasis, ::GateCX) = true

# Control flow and measurement
isterminal(::CanonicalBasis, ::Barrier) = true
isterminal(::CanonicalBasis, ::Measure) = true
isterminal(::CanonicalBasis, ::Reset) = true

# Amplitude and entanglement queries
isterminal(::CanonicalBasis, ::Amplitude) = true
isterminal(::CanonicalBasis, ::SchmidtRank) = true
isterminal(::CanonicalBasis, ::BondDim) = true
isterminal(::CanonicalBasis, ::VonNeumannEntropy) = true

# Classical operations
isterminal(::CanonicalBasis, ::AbstractClassical) = true

# Annotations
isterminal(::CanonicalBasis, ::AbstractAnnotation) = true

# Z-register operations
isterminal(::CanonicalBasis, ::Multiply) = true
isterminal(::CanonicalBasis, ::Add) = true
isterminal(::CanonicalBasis, ::Pow) = true

# Expectation values
isterminal(::CanonicalBasis, ::ExpectationValue) = true

# Delay (preserves timing information)
isterminal(::CanonicalBasis, ::Delay) = true

# Noise channels
isterminal(::CanonicalBasis, ::AbstractKrausChannel) = true

# IfStatement: terminal if inner operation is terminal
isterminal(::CanonicalBasis, op::IfStatement) = isterminal(CanonicalBasis(), getoperation(op))

# Fallback
isterminal(::CanonicalBasis, ::Operation) = false

# --- decomposition via CanonicalRewrite ---

function decompose!(builder, ::CanonicalBasis, op::Operation, qtargets, ctargets, ztargets)
    if matches(CanonicalRewrite(), op)
        return decompose_step!(builder, CanonicalRewrite(), op, qtargets, ctargets, ztargets)
    end
    throw(DecompositionError("Operation $(opname(op)) is not supported by CanonicalBasis and cannot be decomposed."))
end
