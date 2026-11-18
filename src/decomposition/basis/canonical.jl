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
    CanonicalBasis(; borrow=false, max_ancillas=0, allow_measurement=false)

The canonical basis decomposes all operations to a minimal set of primitives:
`GateU`, `GateCX`, `Measure`, `Reset`, and other irreducible operations.

This is the default basis used by [`decompose`](@ref).

# Keyword Arguments

- `borrow::Bool = false`: let decompositions borrow qubits of the circuit
  that the operation does not act on. A borrowed qubit can be in any state;
  the decomposition leaves it as it found it.
- `max_ancillas::Integer = 0`: let decompositions add up to this many clean
  ancillas, numbered after the qubits of the circuit and marked with
  [`AncillaAlloc`](@ref) and [`AncillaFree`](@ref). Ancillas freed by one
  operation are reused by the next.
- `allow_measurement::Bool = false`: with `max_ancillas`, let decompositions
  undo steps by measuring an ancilla into one extra bit, numbered after the
  bits of the circuit. A circuit without bits is refused with an
  `ArgumentError`.

The ancilla options only change how multi-controlled X gates are
decomposed. Circuits whose width is unknown, such as a lone operation, get
no ancillas.

# Examples
```julia
decompose(circuit) # uses CanonicalBasis() by default
decompose(circuit; basis=CanonicalBasis())
```

See also [`DecompositionBasis`](@ref), [`CanonicalRewrite`](@ref).
"""
struct CanonicalBasis <: DecompositionBasis
    ancillas::_AncillaOptions
end

CanonicalBasis(; borrow::Bool=false, max_ancillas::Integer=0, allow_measurement::Bool=false) = CanonicalBasis(_AncillaOptions(borrow, max_ancillas, allow_measurement))

_ancillaoptions(basis::CanonicalBasis) = basis.ancillas

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
isterminal(::CanonicalBasis, ::ReadoutErr) = true
isterminal(::CanonicalBasis, ::Loss) = true
isterminal(::CanonicalBasis, ::Reload) = true
isterminal(::CanonicalBasis, ::Check) = true
isterminal(::CanonicalBasis, ::MeasureCheck) = true

# IfStatement: terminal if inner operation is terminal
isterminal(::CanonicalBasis, op::IfStatement) = isterminal(CanonicalBasis(), getoperation(op))

# WhileStatement: terminal if inner operation is terminal
isterminal(::CanonicalBasis, op::WhileStatement) = isterminal(CanonicalBasis(), getoperation(op))

# Fallback
isterminal(::CanonicalBasis, ::Operation) = false

# --- decomposition via CanonicalRewrite ---

# Only these operations have rules that use the decomposition context. Bases
# take the context for them alone, so a 6-argument `decompose!` method added
# for any other operation type keeps being called.
const _ContextOps = Union{Control,IfStatement}

function decompose!(builder, basis::CanonicalBasis, op::_ContextOps, qtargets, ctargets, ztargets, ctx::DecompositionContext)
    if matches(CanonicalRewrite(), op)
        return decompose_step!(builder, CanonicalRewrite(), op, qtargets, ctargets, ztargets, ctx)
    end
    return decompose!(builder, basis, op, qtargets, ctargets, ztargets)
end

function decompose!(builder, ::CanonicalBasis, op::Operation, qtargets, ctargets, ztargets)
    if matches(CanonicalRewrite(), op)
        return decompose_step!(builder, CanonicalRewrite(), op, qtargets, ctargets, ztargets)
    end
    throw(DecompositionError("Operation $(opname(op)) is not supported by CanonicalBasis and cannot be decomposed."))
end
